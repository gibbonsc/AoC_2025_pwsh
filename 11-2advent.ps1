<# https://adventofcode.com/2025/day/11
  Part 1
  Find distinct paths in a digraph that pass through mandated nodes
  Author: C Gibbons
#>
#$inp = Get-Content ./11-2example1.txt
#$inp = Get-Content ./11-2example2.txt
$inp = Get-Content ./11-input.txt
#$rows = $inp.Count

function Parse-Nodes {
    [CmdletBinding()]param(
        [Parameter(Mandatory = $true)][string[]]$NodeStrings
    )
    [string[]]$Nodes = @()
    $Steps = @{}
    foreach ($ns in $NodeStrings) {
        $k, $v = $ns.Split(":")
        $Nodes += , $k
        $Steps[$k] = $v
    }
    $Nodes += , "out"
    $Steps["out"] = "out: "
    $size = $Nodes.Count
    $StepCounts = [long[, ]]::new($size, $size)
    foreach ($k1 in 0..($size - 1)) {
        foreach ($k2 in 0..($size - 1)) {
            #        if (-1 -lt $Steps[$Nodes[$k1]].IndexOf($Nodes[$k2])
            $Node1Id = $Nodes[$k1]
            $Nexts = $Steps[$Node1Id]
            $Node2Id = $Nodes[$k2]
            $i = $Nexts.IndexOf($Node2Id)
            if (-1 -lt $i) {
                $StepCounts[$k1, $k2] = 1
            }
        }
    }
    [PSCustomObject]@{
        Nodes      = $Nodes
        Steps      = $Steps
        StepCounts = $StepCounts
    }
}

function New-BinOpHash() {
    [CmdletBinding()]param(
        [Parameter(Mandatory = $true)][string[]]$NodeStrings
    )
    $result = @{}
    foreach ($k1 in $NodeStrings) {
        foreach ($k2 in $NodeStrings) {
            $k = "$($k1.SubString(0,3)) $($k2.SubString(0,3))"
            $result[$k] = $null
        }
    }
    Write-Output $result
}

function Take-AnotherStep() {
    [CmdletBinding()]param(
        [Parameter(Mandatory = $true)][string[]]$Nodes,
        [Parameter(Mandatory = $true)][Hashtable]$Steps,
        [Parameter(Mandatory = $true)][long[, ]]$ChoiceCounts
    )
    $size = $Nodes.Count
    $OneMoreStep = [long[, ]]::new($size, $size)
    #[System.Array]::Copy($StepCounts,$OneMoreStep,$size*$size)
    $NextSteps = @{}
    foreach ($k1 in 0..($Nodes.Count - 1)) {
        foreach ($k2 in 0..($Nodes.Count - 1)) {
            if (0 -lt $ChoiceCounts[$k1, $k2]) {
                $Start = $Nodes[$k1]
                $Aheads = $Steps[$Nodes[$k2]].Split(' ')
                $Choices = $Aheads.Count - 1
                foreach ($Choice in 1..$Choices) {
                    $ChoiceNodeId = $Aheads[$Choice]
                    $ChoiceNodeIndex = [Array]::IndexOf($Nodes, $ChoiceNodeId)
                    if ($NextSteps[$Start] -notcontains $ChoiceNodeId) {
                        $NextSteps[$Start] += , $ChoiceNodeId
                    }
                    if (-1 -lt $ChoiceNodeIndex) {                    
                        $OneMoreStep[$k1, $ChoiceNodeIndex] += $ChoiceCounts[$k1, $k2]
                    }
                }
            }
        }
    }
    [PSCustomObject]@{
        NextSteps   = $NextSteps
        OneMoreStep = $OneMoreStep
    }
}

Function Format-LongSquareMatrix {
    param([long[, ]]$Matrix, [long]$Size)
    $result = ""
    foreach ($r in 0..($Size - 1)) {
        $result += '['
        foreach ($c in 0..($Size - 1)) {
            if ($c -ne 0) { $result += ' '}
            $result += $Matrix[$r, $c]
        }
        $result += "]`n"
    }
    $result
}

function Copy-StringArray {
    [CmdletBinding()]param(
        [Parameter(Mandatory = $true)][string[]]$orig
    )
    $c = $orig.Length;
    $copy = [string[]]::new($c)
    [System.Array]::Copy($orig, $copy, $c)
    Write-Output -NoEnumerate $copy
}

function Collect-Paths {
    [CmdletBinding()]param(
        [Parameter(Mandatory = $true)]$NS,
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Sink
    )
    Write-Debug "Searching $Source to $Sink..."
    $CompletedCount = 0
    $c=$NS.Nodes.Count
    $Steps = $NS.Steps
    $TotalCounts = [long[, ]]::new($c,$c); [System.Array]::Copy($NS.StepCounts,$TotalCounts,$c*$c)
    $OneMoreStep = [long[, ]]::new($c,$c); [System.Array]::Copy($NS.StepCounts,$OneMoreStep,$c*$c)
    $r = [Array]::IndexOf($NS.Nodes,$Source)
    $c = [Array]::IndexOf($NS.Nodes,$Sink)
    Write-Debug "$Source at row $r, $Sink at col $c"
    $ArcCount = 1
    while ($Steps.Count -gt 0) {
        if ($OneMoreStep[$r, $c] -gt 0) {
            $CompletedCount += $OneMoreStep[$r,$c]
            Write-Debug "Paths found: $($OneMoreStep[$r,$c]) ($ArcCount steps)"
        }
        $TS = Take-AnotherStep $NS.Nodes $NS.Steps $OneMoreStep
        $Steps = $TS.NextSteps
        $OneMoreStep = $TS.OneMoreStep
        $ArcCount++
    }
    Write-Output $CompletedCount
    # [string[]]$WorkingPaths = @(" $Source")
    # while ($WorkingPaths.Length -gt 0) {
    #     Write-Debug "`tWorking $($WorkingPaths.Count), Completed $($CompletedPaths.Count)"
    #     [string[]]$AdvancingPaths = @()
    #     foreach ($Path in $WorkingPaths) {
    #         [string]$DeviceID = $Path.SubString(($Path.Length - 3), 3)
    #         [string[]]$Branches = $NodeArcs[$DeviceID]
    #         foreach ($Branch in $Branches) {
    #             $Proceed = "$Path $Branch"
    #             if ($Branch -eq $Sink) {
    #                 $CompletedPaths += , @($Proceed)
    #             }
    #             else {
    #                 $AdvancingPaths += , @($Proceed)
    #             }
    #         }
    #     }
    #     $WorkingPaths = $AdvancingPaths
    # }
    # Write-Output -NoEnumerate $CompletedPaths
    # $vs = "`n "
    # $vs += $CompletedPaths | Foreach-Object { ($_ -join ' ') + "`n" }
    # Write-Debug $vs
}

if ($MyInvocation.InvocationName -eq '.') {
    $f1 = Collect-Paths -Debug (Parse-Nodes $inp) 'svr' 'fft'
    $f1
    $f2 = Collect-Paths -Debug (Parse-Nodes $inp) 'fft' 'dac'
    $f2
    $f3 = Collect-Paths -Debug (Parse-Nodes $inp) 'dac' 'out'
    $f3
    "Product: $($f1 * $f2 * $f3)"
}
