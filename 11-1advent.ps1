<# https://adventofcode.com/2025/day/11
  Part 1
  Find distinct paths in a digraph
  Author: C Gibbons
#>
#$inp = Get-Content ./11-1example.txt
$inp = Get-Content ./11-input.txt
#$inp = Get-Content ./11-2example2.txt
#$rows = $inp.Count

function Parse-Nodes {
    [CmdletBinding()]param(
        [Parameter(Mandatory = $true)][string[]]$NodeStrings
    )
    $result = @{}
    foreach ($ns in $NodeStrings) {
        $k, $v = $ns.Split(": ")
        $vs = $v.Split(" ")
        $result[$k] = $vs
    }
    Write-Output $result
}

function Copy-StringArray {
    [CmdletBinding()]param(
        [Parameter(Mandatory=$true)][string[]]$orig
    )
    $c = $orig.Length;
    $copy = [string[]]::new($c)
    [System.Array]::Copy($orig,$copy,$c)
    Write-Output -NoEnumerate $copy
}

function Collect-Paths {
    [CmdletBinding()]param(
        [Parameter(Mandatory = $true)][HashTable]$NodeArcs
    )
    [string[][]]$CompletedPaths = @()
    [string[][]]$WorkingPaths = @(@("you"))
    while ($WorkingPaths.Length -ne 0) {
        [string[][]]$AdvancingPaths = @()
        foreach ($Path in $WorkingPaths) {
            [string]$DeviceID = $Path[$Path.Length - 1]
            [string[]]$Branches = $NodeArcs[$DeviceID]
            foreach ($Branch in $Branches) {
                $Proceed = (Copy-StringArray $Path) + , $Branch
                if ($Branch -eq 'out') {
                    $CompletedPaths += , @($Proceed)
                }
                else {
                    $AdvancingPaths += , @($Proceed)
                }
            }
        }
        $WorkingPaths = $AdvancingPaths
    }
    Write-Output -NoEnumerate $CompletedPaths
    $vs = "`n "
    $vs += $CompletedPaths | Foreach-Object { ($_ -join ' ') + "`n" }
    Write-Debug $vs
}

if ($MyInvocation.InvocationName -eq '.') {
    $p = Collect-Paths -Debug (Parse-Nodes $inp)
    $p.Count
    $parsed = $p | Where-Object {$_ -contains "dac" -and $_ -contains "fft" }
    $parsed.Count
    $vs = "`n "
    $vs += $parsed | Foreach-Object { "`t" + ($_ -join ' ') + "`n" }
    Write-Information -InformationAction Continue $vs
}
