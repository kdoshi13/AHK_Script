#Requires AutoHotkey v2.0
#SingleInstance Force

; === SETTINGS ===
debugKey  := "F9"                                     ; press F9 to show active process (debug)
global scriptEnabled := true                          ; Global variable to control script's active state
toggleKey := "F8"                                     ; Hotkey to toggle script on/off

; Read key mappings from config.ini, or use defaults
wheelUpKey := IniRead("config.ini", "Hotkeys", "WheelUp")
wheelDownKey := IniRead("config.ini", "Hotkeys", "WheelDown")
ableGamesString := IniRead("config.ini", "Hotkeys", "able games")

; Set default values if IniRead returns an empty string (key not found)
if (wheelUpKey = "")
    wheelUpKey := "F"
if (wheelDownKey = "")
    wheelDownKey := "O"

; Parse able games string into an array
global games := []
if (ableGamesString != "") {
    for each, gameExe in StrSplit(ableGamesString, ",") {
        games.Push(Trim(gameExe))
    }
} else {
    ; Default games if not specified in config.ini
    games := ["hollow_knight.exe", "Hollow Knight Silksong.exe"]  ; match your actual exe names
}


; === HOTKEYS ===
Hotkey(debugKey, ShowActiveProcess)
Hotkey(toggleKey, ToggleScript)

; === FUNCTIONS ===
ShowActiveProcess(*) {
    proc := WinGetProcessName("A")
    ShowTempToolTip("Active process: " . (proc ? proc : "none"))
}

ShowTempToolTip(text, duration := 1200) {
    ; bottom-right corner tooltip
    x := A_ScreenWidth - 420
    y := A_ScreenHeight - 60
    ToolTip(text, x, y)
    SetTimer(() => ToolTip(""), -duration)
}

; Function to toggle the script's enabled state
ToggleScript(*) {
    global scriptEnabled
    scriptEnabled := !scriptEnabled
    state := scriptEnabled ? "ENABLED" : "DISABLED"
    ShowTempToolTip("Script " . state, 1500)
}

IsRemapActive() {
    global games, scriptEnabled
    ; Check if the script is globally enabled
    if (!scriptEnabled)
        return false

    ; Check if any of the defined games are active
    for exe in games {
        if WinActive("ahk_exe " exe)
            return true
    }
    return false
}

; === REMAP (only active when IsRemapActive() returns true) ===
; These hotkeys are only active when the script is globally enabled AND
; one of the specified games is the active window.
#HotIf IsRemapActive()
WheelUp::SendInput(wheelUpKey)
WheelDown::SendInput(wheelDownKey)
#HotIf

; Win + W → Open Windows Terminal
#Enter:: {
    try {
        ; Check if we're in File Explorer
        if WinActive("ahk_class CabinetWClass") or WinActive("ahk_class ExploreWClass") {
            ; Get the active explorer window using COM
            shell := ComObject("Shell.Application")
            windows := shell.Windows
            currentPath := ""
            
            ; Iterate through all explorer windows
            for window in windows {
                if window.HWND = WinExist("A") {
                    currentPath := window.Document.Folder.Self.Path
                    break
                }
            }
            
            if (currentPath != "") {
                Run 'wt.exe -d "' currentPath '"'  ; Windows Terminal
            } else {
                Run "wt.exe"
            }
        } else {
            Run "wt.exe"
        }
    } catch {
        ; If anything fails, just open terminal in default location
        Run "wt.exe"
    }
}
CapsLock::Escape
#Requires AutoHotkey v2.0
#c::
{
    path := GetExplorerPath()
    if (path) {
        Run 'codium.cmd "' path '"'
    } else {
        MsgBox "No valid folder detected!", "Error", 48
    }
}

GetExplorerPath() {
    shell := ComObject("Shell.Application")
    for window in shell.Windows() {
        try {
            if (window && InStr(window.FullName, "explorer.exe"))
                return window.Document.Folder.Self.Path
        }
    }
    return ""
}

#w::
{
    ; Close the active window
    try {
        WinClose("A")  ; "A" refers to the active window
    } catch {
        ; If WinClose fails, try Alt+F4 as a fallback
        Send("!{F4}")
    }
}
#Requires AutoHotkey v2.0

#n::  ; Win + N
{
    Click "Middle"	
}

#o:: {
	Run "ms-availablenetworks:"    
}

; === CONTEXT MENU FUNCTIONS ===
; Win + I to install context menu for .ini files
#i::
{
    InstallContextMenu()
}

InstallContextMenu() {
    ; Path to the compiled AHK script (main.exe)
    scriptPath := A_ScriptDir . "\main.exe"

    ; Registry key for .ini files context menu
    regKey := "HKEY_CLASSES_ROOT\.ini\shell\Open with AHK Script"
    regCommandKey := regKey . "\command"

    ; Add the context menu entry
    RegWrite "REG_SZ", regKey, "", "Open with AHK Script"
    commandString := Format("`"{}`" `"%1`"", A_ScriptDir . "\main.exe")
    RegWrite "REG_SZ", regCommandKey, "", commandString

    MsgBox "Context menu entry 'Open with AHK Script' for .ini files installed.", "Success", 64
}

; === COMMAND LINE ARGUMENT HANDLING ===
; Check if the script was launched with a file path argument (e.g., from context menu)
if (A_Args.Length > 0) {
    filePath := A_Args[1]
    if FileExist(filePath) {
        Run "notepad.exe " Chr(34) . filePath . Chr(34)
        ExitApp ; Exit after opening the file
    }
}

; === TASKBAR CONTEXT MENU ===
; This section adds a custom context menu to the AutoHotkey script's taskbar icon.
; This allows users to interact with the script directly from the system tray.

; Directly add items to the existing A_TrayMenu object.
; This modifies the default AutoHotkey tray menu.

; Add an "Open config.ini" item to the tray menu.
; When clicked, it will call the OpenConfigFile function.
A_TrayMenu.Add("Open config.ini", OpenConfigFile)

; Add a separator line for better organization.
A_TrayMenu.Add()

; Add an "Exit" option to the tray menu, which will terminate the script.
A_TrayMenu.Add("Exit", (*) => ExitApp())

; Function to open the config.ini file.
; It constructs the full path to config.ini and opens it using Notepad.
OpenConfigFile(*) {
    Run "notepad.exe " Chr(34) . A_ScriptDir . "\config.ini" . Chr(34)
}

; === AUTO CLEAN TEMP FOLDERS ON START ===
CleanTempFolders() {
    tempFolders := [
        "C:\Users\HollowMe\AppData\Local\Temp",
        "C:\Windows\Temp"
    ]

    for folder in tempFolders {
        if DirExist(folder) {
            try {
                Loop Files folder "\*", "FD" {
                    if (A_LoopFileAttrib ~= "D")
                        DirDelete(A_LoopFileFullPath, true)  ; Delete folder recursively
                    else
                        FileDelete(A_LoopFileFullPath)
                }
            } catch as err {
                ; Uncomment to debug:
                ; MsgBox "Error cleaning " folder ":`n" err.Message, "Error", 16
            }
        }
    }
}

; Run automatically on script start
CleanTempFolders()
