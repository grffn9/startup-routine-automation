@echo off

:: 0. Reset Notion Checkboxes (Run Python Script)
echo Resetting Notion checklists...
python "%~dp0reset_notion_pages.py"

:: 1. Open the specific pages first (they will become tabs)
:: First link needs extra time for Notion to fully initialize
powershell -command "Start-Process 'notion://www.notion.so/Today-s-Targets-1dcc1eef485d80deaebbc9bafeb466b0?source=copy_link'"
timeout /t 5
powershell -command "Start-Process 'notion://www.notion.so/Startup-Routine-21fc1eef485d8058a87ff49f37706365?source=copy_link'"
timeout /t 2
powershell -command "Start-Process 'notion://www.notion.so/Value-Plan-1dcc1eef485d804bae6df704e9e422ae?source=copy_link'"
timeout /t 3
:: Open the different workspace page LAST so it's the active tab when AHK runs
:: Extra delay to let previous tabs fully settle before switching workspaces
:: (This page is in a different workspace, so we open via direct link)
powershell -command "Start-Process 'notion://www.notion.so/e538b4ce1d0242b3b7c6311a1c0b886c?pvs=16'"
timeout /t 5

:: 2. Open Notion Calendar
start "" "C:\Users\griff\AppData\Local\Programs\notion-calendar-web\Notion Calendar.exe"
timeout /t 8

:: 3. Trigger the AHK script to arrange windows
start "" /wait "C:\Users\griff\OneDrive\Documents\Projects\desktop-automation\startup-routine-automation\window-arranger.exe"

:: 4. End on Today's Targets
powershell -command "Start-Process 'notion://www.notion.so/Today-s-Targets-1dcc1eef485d80deaebbc9bafeb466b0?source=copy_link'"
timeout /t 2

:: 5. Exit the batch script
exit