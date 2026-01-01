<# https://adventofcode.com/2025/day/5
  Part 1
  Identify "fresh" IDs
  (numbers that fall inside specific intervals)
  Reminds me of code I had written years before,
    to search timestamped log files within time intervals
    related to an incident of interest.
  Author: C Gibbons
#>

$inp = Get-Content 05-input.txt

class Interval {
    [long]$LB
    [long]$UB
    [string]ToString() {
        return "{0}-{1}" -f $this.LB, $this.UB
    }
    [bool]Holds([long]$num) {
        return $this.LB -le $num -and $num -le $this.UB
    }
}

[Interval[]]$Intervals = @()
[long[]]$Specimens = @()
$IntervalFlag = $true  # input starts listing "fresh" desired intervals
$inp.ForEach(
    {
        if ($_ -eq '') {
            $IntervalFlag = $false  # after blank line, input lists specimen ID numbers
        }
        elseif ($IntervalFlag) {
            $LDigits,$UDigits = $_.Split('-')
            $Intervals += [Interval]@{LB=[long]$LDigits;UB=[long]$UDigits}
        }
        else {
            $Specimens += [long]$_
        }
    }
)
#$Intervals -join ','  # DEBUG
#$Specimens -join ','  # DEBUG

[long[]]$FreshSpecimens = @()
foreach ($specimen in $Specimens) {  # filter out spoiled specimens
    foreach ($interval in $Intervals) {
        if ($interval.Holds($specimen)) {  # fresh
            $FreshSpecimens += $specimen
            break  # once we know it's fresh, move on
        }
    }
}
# $FreshSpecimens
$FreshSpecimens.Length