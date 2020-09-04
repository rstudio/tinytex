$appPath = "$($env:APPDATA)"
Start-Process -ArgumentList "path remove" -FilePath "$($appPath)\TinyTex\bin\win32\tlmgr.bat" -NoNewWindow -Wait
Remove-Item "$($appPath)\TinyTex" -Recurse
