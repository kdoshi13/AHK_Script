; =====================================================
;  Productivity Hotkeys (AutoHotkey v2)
; =====================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode 2

; =====================================================
;  Win + W → Close active window
; =====================================================
#W::
{
    win := WinExist("A")
    if win
    {
        WinClose("ahk_id " win)
        Sleep(500)
        if WinExist("ahk_id " win)
            WinKill("ahk_id " win)
    }
}

; =====================================================
;  Win + Enter → Open Windows Terminal
;  Opens in current folder if File Explorer is active
; =====================================================
#Enter::    
{
    class := WinGetClass("A")

    if (class = "CabinetWClass" || class = "ExploreWClass")
    {
        shellApp   := ComObject("Shell.Application")
        activeHwnd := WinExist("A")
        folderPath := ""

        for window in shellApp.Windows
        {
            try
            {
                if (window.hwnd = activeHwnd)
                {
                    path := window.Document.Folder.Self.Path
                    if (path != "" && DirExist(path))
                        folderPath := path
                }
            }
            catch
            {
                ; skip invalid Explorer windows (e.g. "This PC")
            }
        }

        if (folderPath != "")
        {
            Run('wt.exe -d "' folderPath '"')
        }
        else
        {
            Run("wt.exe")
        }

        WinWaitActive("ahk_exe wt.exe")
        WinActivate("ahk_exe wt.exe")
    }
    else
    {
        Run("wt.exe")
        WinWaitActive("ahk_exe wt.exe")
        WinActivate("ahk_exe wt.exe")
    }
}

; List of program process names where the remap should work
; (Use WindowSpy or Task Manager → Details tab to find process names)
programList := ["hollow_knight.exe","Hollow Knight Silksong.exe"]

; Function to check if current active window belongs to the target list
isTargetProgram() {
    global programList
    processName := WinGetProcessName(WinGetID("A"))
    for item in programList
        if (item = processName)
            return true
    return false
}

; Wheel Up → Send "0" only if active window matches
#HotIf isTargetProgram()
WheelUp::
{
    Send "o"
}

; Wheel Down → Send "h" only if active window matches
WheelDown::
{
    Send "h"
}
#HotIf  ; disable condition for other programs

; Win + O → Show Available Networks (Win10)
#o::
{
    Run("explorer.exe ms-availablenetworks:")
}

; Win + C → Open VS Code Insiders in current Explorer folder (or normally)
#c::
{
    class := WinGetClass("A")

    ; Check if active window is File Explorer
    if (class = "CabinetWClass" || class = "ExploreWClass")
    {
        shellApp   := ComObject("Shell.Application")
        activeHwnd := WinExist("A")
        folderPath := ""

        ; Loop through Explorer windows and match the active one
        for window in shellApp.Windows
        {
            try
            {
                if (window.hwnd = activeHwnd)
                {
                    path := window.Document.Folder.Self.Path
                    if (path != "" && DirExist(path))
                        folderPath := path
                }
            }
            catch
            {
                ; ignore weird Explorer variants
            }
        }

        ; If we found a folder, open Code Insiders there
        if (folderPath != "")
        {
            Run('code-insiders.cmd "' folderPath '"')
            return
        }
    }

    ; Otherwise just open Code Insiders normally
    Run("code-insiders.cmd")
}
