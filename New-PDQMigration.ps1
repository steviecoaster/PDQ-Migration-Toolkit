<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.3.131
	 Created on:   	1/5/2017 3:26 PM
	 Created by:   	svalding
	 Organization: 	Kent State University Tuscarawas
	 Filename:     	New-PDQMigration.ps1
	===========================================================================
	.DESCRIPTION
		This script migrates PDQ Products from one server to another in one simple process..
#>

[CmdletBinding()]
    param (
				
		[Parameter(Mandatory = $true, Position = 0)]
		[string]$oldServer,
		[Parameter(Mandatory = $true, Position = 1)]
		[string]$newServer,
		[Parameter(Mandatory = $true, Position = 2)]
		[ValidateSet("PDQ Deploy", "PDQ Inventory", "Both")]
		[String]$system,
		[Parameter(Mandatory = $false, Position = 3)]
		[string]$FileShare
			
	)

function New-PDQMigration
{
	
	
	
	Try
		{
		Test-WSMan -ComputerName $newServer -ErrorAction Stop 2>$null
	}
	Catch
	{
		Write-Error "$newServer not reachable via WinRM. Script cannot continue."
		Write-Error "For help enabling WinRm on a remote server see: http://www.adminarsenal.com/powershell/enable-psremoting/"
        Break
	}
	


	function Deploy
	{
		#Local services
		Stop-Service -Name pdqdeploy
		
		#Remote services
		Invoke-Command -ComputerName $newServer -ScriptBlock {Stop-Service pdqdeploy}
		
		#Export local registry key to file
		reg export "HKLM\Software\Admin Arsendal\PDQ Deploy" "$FileShare\deploy.reg"
		#Import registry entry to new computer
		Invoke-Command -ComputerName $newServer -ScriptBlock { reg import $args[0]"\deploy.reg" } -ArgumentList $FileShare
		
		#Copy Database to fileshare
		Copy-Item -Path "%programdata\Admin Arsenal\PDQ Deploy\Database.db" -Destination "$FileShare\DeployDatabase.db" -Force
		
		#Copy Database to new Server
		Invoke-Command -ComputerName $newServer -ScriptBlock { Copy-Item -Path $args[0]"\DeployDatabase.db" -Destination "%programdata\Admin Arsenal\PDQ Deploy\Database.db" -Force } -ArgumentList $FileShare
		
		#Start services on new Server
		Invoke-Command -ComputerName $newServer -ScriptBlock {Start-Service -Name pdqdeploy}
		
	} #End Deploy Function
	
	function Inventory
	{
		#Local services
		Stop-Service -Name pdqinventory
		
		#Remote services
		Invoke-Command -ComputerName $newServer -ScriptBlock { Stop-Service pdqinventory }
		reg export "HKLM\Software\Admin Arsenal\PDQ Inventory" "C:\Temp\inventory.reg"
		#Copy Database to fileshare
		Copy-Item -Path "%programdata\Admin Arsenal\PDQ Inventory\Database.db" -Destination "$FileShare\InventoryDatabase.db" -Force
		
		#Copy Database to new Server
		Invoke-Command -ComputerName $newServer -ScriptBlock { Copy-Item -Path $args[0]"\InventoryDatabase.db" -Destination "%programdata\Admin Arsenal\PDQ Inventory\Database.db" -Force } -ArgumentList $FileShare
		
		#Start services on new Server
		Invoke-Command -ComputerName $newServer -ScriptBlock { Start-Service -Name pdqinventory }
	} # End Inventory Function
	
	function Both
	{
	 $steps = @("Deploy","Inventory")
		
		foreach ($step in $steps)
		{
			$step
			
		}
	} # End Both Function
	
	#region System Type Check
	
	If($system -eq "PDQ Deploy"){

        Deploy
        }

    If($system -eq "PDQ Inventory"){
        
        Inventory
        }
    
    If($system -eq "Both"){

        Both
        }
	
	#endregion System Type Check
} #End New-PDQMigration Function

New-PDQMigration