$PSDefaultParameterValues = @{
	"Join-PQ:Destination" = (Get-Location).Path + "\Join-PQ.pq"
}

# Comment-Based Help
<#
.SYNOPSIS
Combines PowerQuery / M files and/or expressions into a single expression.

.DESCRIPTION
Combines any combination of M files (file objects or valid paths to them) and/or expressions into a single M expression.
The base name of each file serves as the identifier for the expression loaded from the file contents.
Expressions are inserted exactly as written.
All expressions are joined with commas and wrapped in either a let ... in statement or record and written to the Destination file.

.PARAMETER Files
One or more FileInfo objects that point to files containing M code.

.PARAMETER Paths
One or more valid paths that point to files containing M code.

.PARAMETER Expressions
One or more M code expressions. Each expression must be in the form 'Identifier = Expression'

.PARAMETER Destination
Path to which the result will be saved. Defaults to Join-PQ.pq in the current working directory.

.PARAMETER Result
An optional Result parameter allows one to insert a final expression

.PARAMETER NoClobber
A switch to prevent overwriting the Destination file. The function will silently fail if it exists.

.EXAMPLE
PS> '1' | Out-File A.pq ; '2' | Out-File B.pq ; '3' | Out-File C.pq ;
PS> Join-PQ -files ( Get-Item ( A.pq ) ) -paths B.pq,C.pq -expressions 'D=4','E=5' -Result 'A+B+D' -Destination 'ABD.pq'
#Returns the ABD.pq file containing 'let #"A" = 1, #"B" = 2, D = 4 in A + B + D'. If executed, the code will return 7.

.LINK
https://github.com/gsimardnet/PowerQueryNet/

.NOTES
This fuction implements no M-code syntax verification or error checking.
All M code must be written as it would be inserted into the Power Query code editor. It must not be written in the section document syntax (semicolon-terminated) used for developing Custom Data Connectors.

#>
function Join-PQ {
	[CmdletBinding()]
	[OutputType([System.IO.FileInfo])]
	param ( #These parameter sets force at least one item to be entered while others are optional.
		[Parameter(Mandatory, ParameterSetName="F" )]
		[Parameter(Mandatory, ParameterSetName="FE" )]
		[Parameter(Mandatory, ParameterSetName="FP" )]
		[Parameter(Mandatory, ParameterSetName="FPE" )]
		[Alias('f')]
		[System.IO.FileInfo[]]$Files
		,
		[Parameter(Mandatory, ParameterSetName='P')]
		[Parameter(Mandatory, ParameterSetName='PE')]
		[Parameter(Mandatory, ParameterSetName='FP')]
		[Parameter(Mandatory, ParameterSetName='FPE')]
		[ValidateScript( { Test-Path -Path $_ -PathType leaf } ) ]
		[Alias('p')]
		[string[]]$Paths
		,
		[Parameter( Mandatory, ParameterSetName="E")]
		[Parameter( Mandatory, ParameterSetName="FE")]
		[Parameter( Mandatory, ParameterSetName="PE")]
		[Parameter( Mandatory, ParameterSetName="FPE")]
		[Alias('e')]
		[string[]]$Expressions
		,
		[Parameter(Mandatory=$false)]
		[Alias('r')]
		[string]
		$Result
		,
		[Parameter(Mandatory=$false)]
		[Alias('d')]
		[ValidateScript( { Test-Path -Path $PSItem -IsValid } ) ]
		[string]$Destination
		,
		[Parameter(Mandatory=$false)]
		[Switch]$NoClobber
	)

	begin { #Convert Paths to File Objects
		$(if ($PSBoundParameters.ContainsKey('Result')) {'let '} else {'['} ) | Out-File -Path $Destination
		$Files += ( $Paths | ForEach-Object { Get-Item $PSItem } )
	}

	process {
		( ( $Files | ForEach-Object {
			'#"' + $PSItem.BaseName + """ = " + ( $PSItem | Get-Content )
		} ) + $Expressions ) | Join-String -Separator "`n,`n" | Out-File -Path $Destination -Append
	}

	end {
		$( if ($PSBoundParameters.ContainsKey('Result')) {" in $Result"} else {']'} ) | Out-File -Path $Destination -Append -NoNewline
		Return Get-Item $Destination
	}
}
