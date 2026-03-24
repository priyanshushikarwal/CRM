; ============================================================
; Doon Infra CRM - Inno Setup Installer Script
; ============================================================
; This installer bundles all required DLLs and runtimes
; so the app runs on any Windows 10+ PC without needing
; any development environment or VC++ Redistributable.
; ============================================================

#define MyAppName "Doon Infra CRM"
#define MyAppVersion "1.0.16"
#define MyAppPublisher "Doon Infra"
#define MyAppExeName "dooninfra_app.exe"

; Paths relative to this .iss file
#define BuildDir "..\build\windows\x64\runner\Release"
#define VCRedistDir "vcredist"

[Setup]
AppId={{B7E3F8A2-4D1C-4E5B-9F6A-2C8D7E1F3A4B}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} v{#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\installer_output
OutputBaseFilename=DoonInfra_CRM_Setup_v{#MyAppVersion}
SetupIconFile=
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
MinVersion=10.0

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; ── Main Application EXE ──
Source: "{#BuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; ── Flutter Engine DLL ──
Source: "{#BuildDir}\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion

; ── Plugin DLLs ──
Source: "{#BuildDir}\app_links_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\url_launcher_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion

; ── Data folder (AOT compiled code, ICU data, assets) ──
Source: "{#BuildDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; ── VC++ Runtime DLLs (CRITICAL for client PCs!) ──
; These are bundled so the app works even without VC++ Redistributable installed
Source: "{#VCRedistDir}\msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#VCRedistDir}\vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#VCRedistDir}\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
