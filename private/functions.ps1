function exportTable {
	param (
		[Parameter(Mandatory=$true)][string]$Path,
		[Parameter(Mandatory=$true)][string]$TabName,
		[Parameter(Mandatory=$true)]$Table
	)
	$Table | Export-Excel -Path $Path -WorksheetName $TabName -ClearSheet -AutoSize -AutoFilter -FreezeTopRowFirstColumn
}
