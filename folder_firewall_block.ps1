Get-ChildItem "folder_path" -Recurse -Filter *.exe | ForEach-Object {
    netsh advfirewall firewall add rule name=("Block_" + $_.BaseName + "_OUT") dir=out action=block program=$_.FullName enable=yes
    netsh advfirewall firewall add rule name=("Block_" + $_.BaseName + "_IN") dir=in action=block program=$_.FullName enable=yes
}
