import 'dart:io';

import 'package:http/http.dart' as http;

class UpdaterService {
  Future<String> fetchText(String url) async {
    final client = http.Client();
    try {
      final response = await client.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Request failed. Status code: ${response.statusCode}');
      }

      return response.body;
    } on HandshakeException catch (_) {
      if (!Platform.isWindows) {
        rethrow;
      }

      return _fetchTextWithPowerShell(url);
    } catch (e) {
      if (Platform.isWindows && _isTlsError(e)) {
        return _fetchTextWithPowerShell(url);
      }

      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> downloadUpdate(
    String url,
    String savePath,
    void Function(double progress) onProgress,
  ) async {
    final file = File(savePath);
    await file.parent.create(recursive: true);

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
    } on HandshakeException catch (_) {
      await _deleteIfExists(file);

      if (!Platform.isWindows) {
        rethrow;
      }

      await _downloadWithPowerShell(url, savePath);
      onProgress(1.0);
    } catch (e) {
      await _deleteIfExists(file);

      if (Platform.isWindows && _isTlsError(e)) {
        await _downloadWithPowerShell(url, savePath);
        onProgress(1.0);
        return;
      }

      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> _downloadWithPowerShell(String url, String savePath) async {
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      r"$ProgressPreference='SilentlyContinue'; "
          r"Invoke-WebRequest -Uri $env:UPDATER_URL -OutFile $env:UPDATER_SAVE_PATH",
    ], environment: {
      'UPDATER_URL': url,
      'UPDATER_SAVE_PATH': savePath,
    });

    if (result.exitCode != 0) {
      final stderr = (result.stderr ?? '').toString().trim();
      final stdout = (result.stdout ?? '').toString().trim();
      final details = stderr.isNotEmpty ? stderr : stdout;
      throw Exception(
        details.isNotEmpty
            ? 'Failed to download update via Windows downloader: $details'
            : 'Failed to download update via Windows downloader.',
      );
    }
  }

  Future<String> _fetchTextWithPowerShell(String url) async {
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      r"$ProgressPreference='SilentlyContinue'; "
          r"(Invoke-WebRequest -Uri $env:UPDATER_URL -UseBasicParsing).Content",
    ], environment: {'UPDATER_URL': url});

    if (result.exitCode != 0) {
      final stderr = (result.stderr ?? '').toString().trim();
      final stdout = (result.stdout ?? '').toString().trim();
      final details = stderr.isNotEmpty ? stderr : stdout;
      throw Exception(
        details.isNotEmpty
            ? 'Failed to fetch update manifest via Windows downloader: $details'
            : 'Failed to fetch update manifest via Windows downloader.',
      );
    }

    return (result.stdout ?? '').toString();
  }

  bool _isTlsError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('certificate_verify_failed') ||
        message.contains('handshakeexception') ||
        message.contains('certificate') && message.contains('issuer');
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> installUpdateAndRestart(String downloadedPackagePath) async {
    final packagePath = downloadedPackagePath.toLowerCase();
    if (packagePath.endsWith('.exe')) {
      await _runInstallerAndExit(downloadedPackagePath);
      return;
    }
    if (packagePath.endsWith('.msi')) {
      await _runMsiInstallerAndExit(downloadedPackagePath);
      return;
    }

    final currentExePath = Platform.resolvedExecutable;
    final appDir = File(currentExePath).parent.path;

    final needsElevation = appDir.toLowerCase().contains('program files');

    final scriptContent = _generateUpdaterScript(
      currentExePath,
      appDir,
      downloadedPackagePath,
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final scriptPath =
        '${Directory.systemTemp.path}\\app_updater_$timestamp.ps1';

    final scriptFile = File(scriptPath);
    await scriptFile.writeAsString(scriptContent);

    if (needsElevation) {
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

  Future<void> _runInstallerAndExit(String installerPath) async {
    await Process.start(installerPath, [
      '/VERYSILENT',
      '/SUPPRESSMSGBOXES',
      '/NORESTART',
    ], mode: ProcessStartMode.detached);

    exit(0);
  }

  Future<void> _runMsiInstallerAndExit(String installerPath) async {
    await Process.start('msiexec', [
      '/i',
      installerPath,
      '/quiet',
      '/norestart',
    ], mode: ProcessStartMode.detached);

    exit(0);
  }

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

  String _escapePowerShellPath(String path) {
    return path.replaceAll("'", "''");
  }
}
