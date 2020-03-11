$mpath = $(Split-Path $Script:MyInvocation.MyCommand.Path)
Get-ChildItem -Path $MPath -Filter '*.ps1' |  ForEach-Object { . $_.FullName }
