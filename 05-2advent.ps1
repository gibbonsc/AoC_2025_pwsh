<# https://adventofcode.com/2025/day/5
  Part 2
  Identify all possible "fresh" IDs
  (not just the identified and inventoried IDs)
  Author: C Gibbons
#>

$inp = Get-Content 05-input.txt

# class Interval {
#     [long]$LB
#     [long]$UB
#     [string]ToString() {
#         return "{0}-{1}" -f $this.LB, $this.UB
#     }
#     [bool]Holds([long]$num) {
#         return $this.LB -le $num -and $num -le $this.UB
#     }
#     [bool]Overlaps([Interval]$i) {
#         return $this.Holds($i.LB) -or $this.Holds($i.UB)
#     }
#     [Interval]Merge([Interval]$i) {
#         if ($this.Overlaps($i)) {
#             if ($i.LB -lt $this.LB) { $this.LB = $i.LB }
#             if ($i.UB -gt $this.UB) { $this.UB = $i.UB }
#             return $this   # returns a reference to $this
#         }
#         else {
#             return $i
#         }
#     }
# }


class Interval {
    [long]$LB
    [long]$UB

    Interval([long]$lb, [long]$ub) {
        if ($ub -lt $lb) { throw "Upper bound must be ≥ lower bound" }
        $this.LB = $lb
        $this.UB = $ub
    }

    # Inclusive length for closed intervals
    [long] GetSize() {
        return ($this.UB - $this.LB + 1)
    }

    [string] ToString() {
        return "{0}-{1}" -f $this.LB, $this.UB
    }

    # Instance Holds (useful for spot checks)
    [bool] Holds([long]$num) {
        return $this.LB -le $num -and $num -le $this.UB
    }

    # --- Static helpers ---

    # Overlap for closed intervals, including adjacency.
    # Adjacent means (a.UB + 1 == b.LB) or (b.UB + 1 == a.LB), which is covered by the inequality.
    static [bool] Overlaps([Interval]$a, [Interval]$b) {
        return [Math]::Max($a.LB, $b.LB) -le ([Math]::Min($a.UB, $b.UB) + 1)
    }

    # Non-mutating union: returns a NEW Interval if overlap/adjacency; otherwise $null.
    static [Interval] Union([Interval]$a, [Interval]$b) {
        if (-not [Interval]::Overlaps($a, $b)) { return $null }
        $lowB = [Math]::Min($a.LB, $b.LB)
        $uppB = [Math]::Max($a.UB, $b.UB)
        return [Interval]::new($lowB, $uppB)
    }
}

[Interval[]]$Intervals = @()
[long[]]$Specimens = @()
$IntervalFlag = $true
$inp.ForEach(
    {
        if ($_ -eq '') {
            $IntervalFlag = $false
        }
        elseif ($IntervalFlag) {
            $LDigits, $UDigits = $_.Split('-')
            $Intervals += [Interval]::new([long]$LDigits, [long]$UDigits)
        }
        else {
            $Specimens += [long]$_
        }
    }
)
#$Intervals -join ','  # DEBUG
#$Specimens -join ','  # DEBUG
$SortedIntervals = $Intervals | Sort-Object { $_.GetSize() }
#[Interval[]]$FreshIntervals = @()

function Compress-Intervals {
    param([Interval[]]$Intervals)

    if (-not $Intervals) { return @() }

    $sorted  = $Intervals | Sort-Object LB, UB
    $result  = New-Object System.Collections.Generic.List[Interval]
    $current = [Interval]::new($sorted[0].LB, $sorted[0].UB)

    foreach ($i in $sorted[1..($sorted.Count - 1)]) {
        $u = [Interval]::Union($current, $i)
        if ($u) { $current = $u }
        else    { $result.Add($current); $current = [Interval]::new($i.LB, $i.UB) }
    }
    $result.Add($current)

    # Sort narrowest → widest, then LB, UB
    # Use either GetSize() (Fix 1) or Size ScriptProperty (Fix 2)
    return $result | Sort-Object { $_.GetSize() }, LB, UB
    # or: return $result | Sort-Object Size, LB, UB
}

[Interval[]]$FreshIntervals = Compress-Intervals $SortedIntervals

$FreshIntervals | ForEach-Object {Write-Output "$($_.ToString())`t $($_.GetSize())"}

$FreshIntervals | ForEach-Object {[long]$t=0}{ $t += $_.GetSize() }{ $t }

# function Compress-FreshIntervals([Interval]$interval) {
#     foreach ($freshInterval in $FreshIntervals) {
#         if ($interval.Holds($freshInterval.LB) -or $interval.Holds($freshInterval.UB)) {
#             $freshInterval.Merge($interval)
#         }
#     }
# }

# foreach ($interval in $Intervals) {
#     $disjointFlag = $true
#     foreach ($freshInterval in $FreshIntervals) {
#         if ($freshInterval.Overlaps($interval)) {
#             $disjointFlag = $false
#             break
#         }
#     }
#     if ($disjointFlag) {
#         $FreshIntervals += $interval
#     }
#     else {
#         Compress-FreshIntervals($Interval)
#     }
# }

# $FreshSpecimenTable.Count