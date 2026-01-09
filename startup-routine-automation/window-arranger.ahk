; AutoHotkey v2 Syntax
#Requires AutoHotkey v2.0
SetTitleMatchMode 2

; Give apps a moment to fully initialize their windows
Sleep 2000

; 1. Handle Main Notion App (Display 2 - Primary)
; Using ahk_exe is more reliable than ahk_class for Electron apps
notionExe := "ahk_exe Notion.exe"
if WinWait(notionExe, , 15) {
    Sleep 500  ; Let window fully render
    WinActivate notionExe
    Sleep 200
    WinRestore notionExe  ; Restore first in case it's already maximized (prevents move issues)
    Sleep 200
    WinMove 0, 0, 1920, 1080, notionExe
    Sleep 200
    WinMaximize notionExe
    
    ; Store the main window's ID so we can identify the new one later
    mainNotionHwnd := WinGetID(notionExe)
    existingNotionWindows := WinGetList(notionExe)
    
    ; 2. Create a NEW Notion window for Missing Semester
    ; The startup.bat opened Missing Semester as the LAST tab, so it's currently active
    ; Ctrl+Shift+N opens the current page in a new window
    Sleep 300
    Send "^+n"
    Sleep 1500  ; Wait for new window to spawn
    
    ; Find the NEW Notion window (not the main one)
    ; Prefer the window that was not present before Ctrl+Shift+N
    newNotionHwnd := 0
    allNotionWindows := WinGetList(notionExe)
    for hwnd in allNotionWindows {
        if (hwnd == mainNotionHwnd)
            continue

        wasExisting := false
        for existingHwnd in existingNotionWindows {
            if (hwnd == existingHwnd) {
                wasExisting := true
                break
            }
        }

        if (!wasExisting) {
            newNotionHwnd := hwnd
            break
        }
    }

    ; Fallback: if we couldn't diff reliably, pick any other Notion window
    if (newNotionHwnd == 0) {
        for hwnd in allNotionWindows {
            if (hwnd != mainNotionHwnd) {
                newNotionHwnd := hwnd
                break
            }
        }
    }
    
    if (newNotionHwnd != 0) {
        ; Position the new Notion window (Missing Semester) on Secondary monitor (Left)
        ; Coordinate -1920 is the exact left edge of the secondary monitor based on debug output
        WinRestore newNotionHwnd
        Sleep 200
        WinMove -1920, 0, 1920, 1080, newNotionHwnd
        Sleep 200
        WinMaximize newNotionHwnd

        ; Switch back to main window and close the leftover tab (the page we just popped out)
        WinActivate mainNotionHwnd
        Sleep 300
        Send "^w"
        Sleep 300
    }
    
    ; Re-position main Notion window on primary monitor (it may have moved)
    WinActivate mainNotionHwnd
    Sleep 200
    WinRestore mainNotionHwnd
    Sleep 200
    WinMove 0, 0, 1920, 1080, mainNotionHwnd
    Sleep 200
    WinMaximize mainNotionHwnd
}

; 3. Handle Notion Calendar (Display 1 - Portrait, stacked with Missing Semester)
; Notion Calendar has a different executable name
calendarExe := "ahk_exe Notion Calendar.exe"
if WinWait(calendarExe, , 15) {
    Sleep 500  ; Let window fully render
    WinActivate calendarExe
    Sleep 200
    WinRestore calendarExe  ; Restore first in case it's already maximized
    Sleep 200
    ; Position Notion Calendar on Secondary monitor (Left)
    ; Coordinate -1920 is the exact left edge of the secondary monitor
    WinMove -1920, 0, 1920, 1080, calendarExe
    Sleep 200
    WinMaximize calendarExe
}