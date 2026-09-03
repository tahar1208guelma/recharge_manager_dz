; Inno Setup Script for Recharge Manager DZ (With Automatic Visual C++ Runtime Installer)
#define MyAppName "Recharge Manager DZ"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Recharge Manager DZ Team"
#define MyAppExeName "recharge_manager_dz.exe"

[Setup]
AppId={{D4180A2E-8E7C-4C91-B73E-9F9C8612A0D1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\..\dist
OutputBaseFilename=RechargeManagerDZ_v1.0_Windows_Setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Include Visual C++ Redistributable if present in installer directory
Source: "vcredist_x64.exe"; DestDir: "{tmp}"; Flags: ignoreversion deleteafterinstall; Check: NeedVCRedist

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Install Visual C++ silently if needed before starting
Filename: "{tmp}\vcredist_x64.exe"; Parameters: "/install /passive /norestart"; Flags: waituntilterminated; Check: NeedVCRedist
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Check if Visual C++ 2015-2022 Redistributable is already installed
function NeedVCRedist(): Boolean;
var
  Installed: Cardinal;
begin
  Result := True;
  if RegQueryDWordValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\X64', 'Installed', Installed) then
  begin
    if Installed = 1 then
      Result := False;
  end;
  if Result and RegQueryDWordValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\X64', 'Installed', Installed) then
  begin
    if Installed = 1 then
      Result := False;
  end;
end;
