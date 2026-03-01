import 'dart:io';

import 'package:http/http.dart' as http;

class UpdaterService {
  /// Downloads a file from [url] to [savePath] with streaming progress.
  /// [onProgress] receives a value between 0.0 and 1.0.
  Future<void> downloadUpdate(
    String url,
    String savePath,
    void Function(double progress) onProgress,
  ) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download update. Status code: ${response.statusCode}',
        );
      }

      final totalBytes = response.contentLength ?? -1;
      int bytesReceived = 0;

      final file = File(savePath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        bytesReceived += chunk.length;
        if (totalBytes > 0) {
          onProgress(bytesReceived / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();
    } finally {
      client.close();
    }
  }

  /// Installs the downloaded ZIP update and restarts the application.
  /// The ZIP must contain the full release folder (EXE + DLLs + data/).
  /// A hidden PowerShell script extracts, backs up, replaces, and relaunches.
  Future<void> installUpdateAndRestart(String downloadedZipPath) async {
    final currentExePath = Platform.resolvedExecutable;
    // The app install directory (where the EXE + DLLs + data/ live)
    final appDir = File(currentExePath).parent.path;

    // Check if app is in a protected directory (Program Files etc.)
    final needsElevation = appDir.toLowerCase().contains('program files');

    final scriptContent = _generateUpdaterScript(
      currentExePath,
      appDir,
      downloadedZipPath,
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final scriptPath =
        '${Directory.systemTemp.path}\\app_updater_$timestamp.ps1';

    final scriptFile = File(scriptPath);
    await scriptFile.writeAsString(scriptContent);

    if (needsElevation) {
      // Launch PowerShell as Administrator using Start-Process -Verb RunAs
      await Process.start('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-WindowStyle',
        'Hidden',
        '-Command',
        'Start-Process powershell -ArgumentList \'-NoProfile\',\'-ExecutionPolicy\',\'Bypass\',\'-WindowStyle\',\'Hidden\',\'-File\',\'$scriptPath\' -Verb RunAs',
      ]);
    } else {
      await Process.start('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-WindowStyle',
        'Hidden',
        '-File',
        scriptPath,
      ]);
    }

    exit(0);
  }

  /// Generates a PowerShell script that:
  /// 1. Waits for the app to exit
  /// 2. Backs up the current app folder to <appDir>_backup
  /// 3. Extracts the ZIP into a temp folder
  /// 4. Copies all extracted files (EXE + DLLs + data/) over the app folder
  /// 5. Restarts the app
  /// 6. Cleans up temp files and itself
  String _generateUpdaterScript(
    String currentExePath,
    String appDir,
    String zipPath,
  ) {
    final escapedExe = _escapePowerShellPath(currentExePath);
    final escapedAppDir = _escapePowerShellPath(appDir);
    final escapedZip = _escapePowerShellPath(zipPath);

    final exeName =
        currentExePath.split('\\').last.replaceAll('.exe', '');
    final escapedProcessName = _escapePowerShellPath(exeName);

    return """
\$logFile = "\$env:TEMP\\app_updater.log"

function Log(\$message) {
    \$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "\$timestamp - \$message" | Out-File -FilePath \$logFile -Append -Encoding utf8
}

try {
    Log "Update script started."
    Log "Current EXE: $escapedExe"
    Log "App directory: $escapedAppDir"
    Log "Downloaded ZIP: $escapedZip"

    \$processName = '$escapedProcessName'
    \$appDir = '$escapedAppDir'
    \$zipPath = '$escapedZip'
    \$currentExe = '$escapedExe'
    \$extractDir = "\$env:TEMP\\app_update_extracted_\$([System.DateTimeOffset]::Now.ToUnixTimeMilliseconds())"
    \$backupDir = "\${appDir}_backup"

    # ── 1. Wait for app to exit ──────────────────────────────────────
    Log "Waiting for process '\$processName' to exit..."
    for (\$i = 0; \$i -lt 30; \$i++) {
        \$proc = Get-Process -Name \$processName -ErrorAction SilentlyContinue
        if (-not \$proc) {
            Log "Process exited after \$i seconds."
            break
        }
        Start-Sleep -Seconds 1
    }

    \$proc = Get-Process -Name \$processName -ErrorAction SilentlyContinue
    if (\$proc) {
        Log "Process still running after 30 seconds. Forcing stop."
        Stop-Process -Name \$processName -Force
        Start-Sleep -Seconds 2
        Log "Process forcefully stopped."
    }

    # ── 2. Extract ZIP to temp folder ────────────────────────────────
    Log "Extracting ZIP to \$extractDir"
    if (Test-Path \$extractDir) { Remove-Item \$extractDir -Recurse -Force }
    Expand-Archive -Path \$zipPath -DestinationPath \$extractDir -Force
    Log "ZIP extracted."

    # Find the actual release folder inside the extracted dir.
    # If the ZIP has a single subfolder, use its contents.
    \$items = Get-ChildItem -Path \$extractDir
    \$sourceDir = \$extractDir
    if (\$items.Count -eq 1 -and \$items[0].PSIsContainer) {
        \$sourceDir = \$items[0].FullName
        Log "Using subfolder: \$sourceDir"
    }

    # ── 3. Backup current app directory ──────────────────────────────
    Log "Backing up current app to \$backupDir"
    if (Test-Path \$backupDir) { Remove-Item \$backupDir -Recurse -Force }
    Copy-Item \$appDir \$backupDir -Recurse -Force
    Log "Backup created."

    # ── 4. Copy new files over (EXE + DLLs + data/ etc.) ────────────
    Log "Copying new files from \$sourceDir to \$appDir"
    Copy-Item -Path "\$sourceDir\\*" -Destination \$appDir -Recurse -Force
    Log "Files replaced successfully."

    # ── 5. Cleanup temp files ────────────────────────────────────────
    Log "Cleaning up temporary files."
    if (Test-Path \$zipPath) { Remove-Item \$zipPath -Force }
    if (Test-Path \$extractDir) { Remove-Item \$extractDir -Recurse -Force }
    Log "Temp files cleaned."

    # ── 6. Restart application ───────────────────────────────────────
    Log "Restarting application."
    Start-Process \$currentExe
    Log "Application restarted."

    # ── 7. Self-delete script ────────────────────────────────────────
    Log "Cleaning up update script."
    Remove-Item \$MyInvocation.MyCommand.Path -Force

} catch {
    Log "ERROR: \$_"
    Log "Stack trace: \$(\$_.ScriptStackTrace)"
}
""";
  }

  /// Escapes a path string for safe embedding in PowerShell single-quoted strings.
  String _escapePowerShellPath(String path) {
    return path.replaceAll("'", "''");
  }
}
