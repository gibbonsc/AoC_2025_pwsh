<# https://adventofcode.com/2025/day/10
  Part 1
  Optimized (minimum) button presses to reach a binary configuration
  Author: C Gibbons
#>
[CmdletBinding()]

#$inp = Get-Content .\10-example.txt
$inp = Get-Content .\10-input.txt
#$rows = $inp.Count

#Write-Host $MyInvocation.InvocationName

$machineStrings = @()
foreach ($row in $inp) {
    $machineStrings += , $row
}

Function Convert-MachineString {
    [CmdletBinding()]param(
        [string]$machineString
    )
    $machineString = $machineStrings[$m]
    $mss = $machineString.Split(" ")
    $lampCount = $mss[0].Length - 2
    $indicator = $mss[0].SubString(1, $lampCount)
    $buttonCount = $mss.Length - 2
    $togglerStrings = $mss[1..($buttonCount)]
    $js = $mss[$buttonCount + 1]

    [int[][]]$buttons = @()
    foreach ($i in 0..($buttonCount - 1)) {
        $tlen = $togglerStrings[$i].Length
        $ts = $togglerStrings[$i].Substring(1, ($tlen - 2))
        [int[]]$toggles = $ts.Split(',')
        $buttons += , @($toggles)
        Write-Debug ( "[i={0,2}] {1}" -f $i, ($toggles -join ',') )
    }
    return @($indicator, $buttons, $js)
}

Function Get-Lamp {
    param(
        [Parameter(Mandatory = $true)][char]$c
    )
    return $c -eq '#'
}

Function Switch-Lamp {
    param(
        [Parameter(Mandatory = $true)][char]$c
    )
    if (Get-Lamp $c) {
        return "."
    }
    else {
        return "#"
    }
}

Function Search-Buttons {
    [CmdletBinding()]param(
        [int[][]]$buttonArray,
        [string]$lampPattern,
        [string]$target
    )
    $met = $false
    $lampStates = @()
    for ($b = 0; $b -lt $buttonArray.Count; $b++) {
        $toggleArray = @($buttonArray[$b])
        $lampState = ""
        for ($d = 0; $d -lt $lampPattern.Length; $d++) {
            if ($d -in $toggleArray) {
                $lampState += Switch-Lamp $lampPattern[$d]
            }
            else {
                $lampState += $lampPattern[$d]
            }
        }
        if ($lampState -eq $target) {
            Write-Debug ("`t`t[b={0,2}] {1} met" -f $b, $lampState)
            $met = $true
            break
        }
        #Write-Debug ("`t`t[b={0,2}] {1}" -f $b, $lampState)
        $lampStates += , $lampState
    }
    return @($met,$lampStates)
}

Function Invoke-MachineTrials {
    [CmdletBinding()]param(
        [string[]] $machineStrings
    )

    for (
        $m = 0;
        $m -lt $machineStrings.Length;
        $m++ 
    ) {
        $searchCache = @{}  # clear cache between machines
        $machineString = $machineStrings[$m]
        $indicator, $buttons, $js = Convert-MachineString $machineString
        $state = "{0}" -f ("." * $indicator.Length)

        Write-Debug ("[m={0,3}] {1}" -f $m, $machineString)
        $depth = 0
        $searching = $indicator -ne $state
        $stateList = @($state)
        while ($searching) {
            $depth++
            Write-Debug "`t`tDepth: $depth"
            [string[]]$deeperList = @()
            foreach ($stateRecord in $stateList ) {
                if ($stateRecord -in $searchCache.Keys) { continue }  # cached, already searched
                $searchCache[$stateRecord] = $true  # cache
                $found, $nextStates = Search-Buttons $buttons $stateRecord $indicator
                $deeperList += $nextStates
                if ($found) {
                    $searching = $false
                    break
                }
            }
            $stateList = $deeperList
        }
        Write-Output $depth
    }
}

if ($MyInvocation.InvocatinName -ne '.') { Invoke-MachineTrials $machineStrings | measure -sum }
