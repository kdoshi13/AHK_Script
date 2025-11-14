Get-NetFirewallRule | Where-Object { $_.Name -like "Block_*" } | ForEach-Object {
    netsh advfirewall firewall delete rule name=$_.Name
}
