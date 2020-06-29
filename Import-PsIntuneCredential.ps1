function Import-PsIntuneCredential {
	[CmdletBinding()]
	param (
		[parameter()][string] $Path = "",
		[parameter()][string] $Folder = ""
	)
	try {
		if ([string]::IsNullOrEmpty($Path)) {
			Write-Verbose "preparing file selection dialog"
			Add-Type -AssemblyName System.Windows.Forms
			$fileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
				InitialDirectory = $Folder
				Filter = 'XML Documents|*.xml'
				Title = 'Select Credential File to Import'
				Multiselect = $False
			}
			Write-Verbose "opening file selection dialog"
			$null = $fileBrowser.ShowDialog()
			$Path = $fileBrowser.FileName
			Write-Verbose "selected file: $Path"
		}
		if (-not ([string]::IsNullOrEmpty($Path))) {
			$result = Import-Clixml $Path
		}
	}
	catch {
		Write-Error $_.Exception.Message 
	}
	finally {
		Write-Output $result
	}
}