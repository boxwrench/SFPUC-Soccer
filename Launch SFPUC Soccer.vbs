Set shell = CreateObject("WScript.Shell")
Set files = CreateObject("Scripting.FileSystemObject")
projectFolder = files.GetParentFolderName(WScript.ScriptFullName)
shell.Run "godot.exe --path """ & projectFolder & """", 1, False