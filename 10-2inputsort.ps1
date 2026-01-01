#[CmdletBinding()]

#$inp = Get-Content .\10-example.txt
#$inp = Get-Content .\10-example2.txt
$inp = Get-Content .\10-input.txt
#$rows = $inp.Count

$machineStrings = @()
foreach ($row in $inp) {
    $machineStrings += , $row
}

Function Convert-MachineString {
    [CmdletBinding()]param(
        [string]$machineString
    )
    $mss = $machineString.Split(" ")  # indicator first/target joltages last/buttons in-between
    $numButtons = $mss.Length - 2
    $togglerStrings = $mss[1..($numButtons)]  # buttons in-between
    $js = $mss[$numButtons + 1]  # joltage targets last
    [int[]]$jLimits = $js.Substring(1, $js.Length - 2).Split(',')  # individual targets
    #$jh = ($jLimits | ForEach-Object -Begin { $i = 0 } -Process { '{0}={1}' -f ($i++), $_
    #    }) -join "`n" | ConvertFrom-StringData  # joltage targets hashtable

    [int[][]]$buttons = @()
    foreach ($i in 0..($numButtons - 1)) {
        # get each buttons' connections
        $tlen = $togglerStrings[$i].Length
        $ts = $togglerStrings[$i].Substring(1, ($tlen - 2))
        [int[]]$toggles = $ts.Split(',')
        $buttons += , @($toggles)
        #Write-Debug ( "[i={0,2}] {1}" -f $i, ($toggles -join ',') )
    }
    #Write-Debug ( "{{{0}}}" -f ($jLimits -join ',') )
    return @( $mss[0], $buttons, $jLimits )
}

Function ConvertTo-Dual {
    [CmdletBinding()]param(
        [int[][]] $Lbb
    )
    $range = $Lbb | Foreach-Object { $_ } | Sort-Object -Unique
    $Bbl = [int[][]]@()
    for ($d = 0; $d -lt $range.Length; $d++) {
        [int[]]$primer = [int[]]@()
        for ($b = 0; $b -lt $Lbb.Length; $b++) {
            if ($Lbb[$b] -contains $d) {
                $primer += , $b
            }
        }
        $Bbl += , $primer
    }
    return $Bbl
}

Function Push-ButtonNTimes {
    param(
        [int[]]$ButtonEffects,
        [int[]]$MachineStatus,
        [int]$N
    )
    for ($d = 0; $d -lt $ButtonEffects.Count; $d++) {
        $MachineStatus[$ButtonEffects[$d]] -= $N
        if ($MachineStatus[$ButtonEffects[$d]] -lt 0) {
            return $false  # bust
        }
    }
    return $true
}

Function Expand-AllPushCandidates {
    [CmdletBinding()]param(
        [int[]]$PushConstraints
    )
    [int[]]$odometer = @(0) * $PushConstraints.Count
    $underflow = $true
    while ($underflow) {
        Write-Output -NoEnumerate @($odometer)
        #Write-Information -InformationAction Continue ($odometer -join ',')
        for ($i = $odometer.Count - 1; $i -ge 0; $i--) {
            $inc = ++$odometer[$i]
            if ($inc -gt $PushConstraints[$i] ) {
                $odometer[$i] = 0
                if ($i -eq 0) { $underflow = $false }
            }
            else {
                break
            }
        }
    }
}

Function Get-ConstrainedAdditivePartitions {
    [CmdletBinding()]param(
        [int[][]]$Bconns,
        [int[]]$jTs  # constrained by these joltage targets
    )
    [int[]]$pushCeiling = @()
    foreach ($b in $Bconns) {
        $m = [int]::MaxValue  # find maximum allowed button presses
        foreach ($d in $b) {
            if ($jTs[$d] -lt $m) { $m = $jTs[$d] }
        }
        $pushCeiling += , $m
    }
    $allCandidates = Expand-AllPushCandidates $pushCeiling
    foreach ($candidate in $allCandidates) {
        $jTsCopy = [int[]]::new($jTs.Count)
        [System.Array]::Copy($jTs, $jTsCopy, $jTs.Count)
        for ($i = 0; $i -lt $candidate.Count; $i++) {
            [int[]]$b = $Bconns[$i]
            [int]$n = $candidate[$i]
            Push-ButtonNTimes $b $jTsCopy $n
        }
        $op = $true
        for ($i = 0; $i -lt $jTsCopy.Count; $i++) {
            if ($jTsCopy[$i] -ne 0) { $op = $false; break }
        }
        if ($op) { Write-Output -NoEnumerate $candidate }
    }
}

Function Step-ThroughPushCandidates {
    [CmdletBinding()]param(
        [int[][]]$Bconns,
        [int[]]$jTs  # constrain by joltage targets
    )
    [int[]]$pushCeiling = @()
    foreach ($b in $Bconns) {
        $m = [int]::MaxValue  # find maximum allowed presses by this button
        foreach ($d in $b) {
            if ($jTs[$d] -lt $m) { $m = $jTs[$d] }
        }
        $pushCeiling += , $m
    }
    # build a custom odometer iterator
    [int[]]$odometer = @(0) * $pushCeiling.Count
    $underflow = $true
    [long]$tally = 0
    while ($underflow) {
        # copy the joltage targets and push odometer-counted buttons against it
        $jBuster = -1
        $tally++
        if (($tally % 100000) -eq 0) { Write-Debug ("`t`t {0:N0}" -f $tally) }
        $c = $jTs.Count; $jTsCopy = [int[]]::new($c); [System.Array]::Copy($jTs, $jTsCopy, $c)
        for ($i = 0; $i -lt $odometer.Count; $i++) {
            [int[]]$b = $Bconns[$i]
            [int]$n = $odometer[$i]
            $inPlay = Push-ButtonNTimes $b $jTsCopy $n
            if (-not $inPlay) { $jBuster = $i; break }
        }
        if ($inPlay) {
            $op = $true
            for ($i = 0; $i -lt $jTsCopy.Count; $i++) {
                if ($jTsCopy[$i] -ne 0) { $op = $false; break }
            }
            if ($op) {
                Write-Output ($odometer -join ',')
            }
            for ($i = $odometer.Count - 1; $i -ge 0; $i--) {
                # increment odometer
                $inc = ++$odometer[$i]
                if ($inc -gt $pushCeiling[$i]) {
                    $odometer[$i] = 0
                    if ($i -eq 0 ) { $underflow = $false }
                }
                else {
                    break
                }
            }
        }
        else {
            # busted; no longer in play, so crank odometer forward:
            if ($jBuster -eq 0) { $underflow = $false; continue }
            for ($i = $odometer.Count - 1; $i -ge $jBuster; $i--) {
                # zero odometer up to $jBuster
                $odometer[$i] = 0
            }
            for ($i = $jBuster - 1; $i -ge 0; $i--) {
                # increment remainder of odometer
                $inc = ++$odometer[$i]
                if ($inc -gt $pushCeiling[$i]) {
                    $odometer[$i] = 0
                    if ($i -eq 0 ) { $underflow = $false }
                }
                else {
                    break
                }
            }
        }
    }
    Write-Debug ("`tExamined {0:N0} sequencees for this machine" -f $tally)
}


Function Sort-Machines {
    [CmdletBinding()]param(
        [string[]] $machineStrings
    )

    $machineHashes = @{}
    for (
        $m = 0;
        $m -lt $machineStrings.Length;
        $m++
    ) {
        # #$searchCache = @{}  # clear cache between machines
        $machineString = $machineStrings[$m]
        [string]$indicator, [int[][]]$buttons, [int[]]$js = Convert-MachineString $machineString

        $format = "Targets: {{{0}}}`nButtons: {1}`n  Lamps: {2}"
        $formatButtons = ""
        for ($b = 0; $b -lt $buttons.Count; $b++) {
            $formatButtons += " [$b]:(" + ($buttons[$b] -join ",") + ")"
        }
        $lamps = ConvertTo-Dual $buttons
        $formatLamps = ""
        for ($d = 0; $d -lt $lamps.Count; $d++) {
            $formatLamps += (" [{0}]:({1})" -f $d, ($lamps[$d] -join ','))
        }
        Write-Debug ($format -f ($js -join ' '), $formatButtons, $formatLamps)

        $machineHashes[$machineString] = 10*($buttons.Count-1)*($lamps.Count-1)
        # [string[]]$constraniedCandidates = Step-ThroughPushCandidates $buttons $js
        # Write-Debug ("Collected:`n{0}" -f ($constraniedCandidates -join "`n"))
        # $maxPresses = [int]::MaxValue
        # foreach ($candidate in $constraniedCandidates) {
        #    $presses = $candidate.Split(',')
        #    $pressCount = ($presses | Measure-Object -Sum).Sum
        #    if ($pressCount -lt $maxPresses) {
        #        $maxPresses = $pressCount
        #    }
        # }
        # Write-Output $maxPresses
    }
    foreach ($item in $machineHashes.GetENumerator() | Sort-Object Value ) {
        Write-Output $item.Name
    }
}

#if ($MyInvocation.InvocationName -eq '.') { Invoke-MachineTrials $machineStrings -Debug }
