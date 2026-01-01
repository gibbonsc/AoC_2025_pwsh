<# https://adventofcode.com/2025/day/2
  Part 1
  Discover and sum invalid ID numbers.
  (IDs that consist of numeral sequences repeated once)
  Author: C Gibbons
#>

# collect intervals
class Interval {
    [long]$LB
    [long]$UB

    Interval($l,$u) { $this.LB = $l; $this.UB = $u }
    [string] ToString() {
        $result = "{0,11}, {1,11}" -f $this.LB,$this.UB
        return $result
    }
}

Function Read-Intervals {
    param(
        [Parameter(ValueFromPipeline)]
        [string]$Intervals
    )
    process {
        $IntervalList = [Interval[]]@()
        $IntervalText = $Intervals.Split(",")
        foreach ($Text in $IntervalText) {
            $LBText,$UBText = $Text.Split("-")
            $LB,$UB = [long]$LBText,[long]$UBText
            $Interval = [Interval]::new($LB,$UB)
            $IntervalList += $Interval
        }
        return $IntervalList
    }
}

function Get-EvenRanges {
    $ranges = (Get-Content .\02-input.txt | Read-Intervals | Sort-Object -Property UB)
    #$rangeMax = 0
    foreach ($range in $ranges) {
        # how many decimal digits in the lower bound?
        $LowerBound = $range.LB
        $LDigits = [math]::floor([math]::log10($range.LB)) + 1
        # if odd number of digits, shift bound up to next power of 10
        if (1 -eq [int]$LDigits % 2) {
            $LowerBound = [long][math]::pow(10,$LDigits)
        }
        # how many decimal digits in the upper bound?
        $UpperBound = $range.UB
        $UDigits = [math]::floor([math]::log10($range.UB)) + 1
        # if odd number of digits, shift bound down past previous power of 10
        if (1 -eq [int]$UDigits % 2) {
            $UpperBound = [long][math]::pow(10,$Udigits-1) - 1
        }
        # if both bounds had the same odd number of digits, skip that range
        if ($LowerBound -le $UpperBound) {
            $Interval = [Interval]::new($LowerBound,$UpperBound)
            Write-Output $Interval
        }
    }
}

function Process-EvenRanges {
    param(
        [Parameter(ValueFromPipeline)]
        [Interval]$range
    )
    process {
        $LoDigits = [string]$range.LB
        $Half = ($LoDigits.Length) / 2
        $LoMSDs = $LoDigits.Substring(0,$Half)
        $HiDigits = [string]$range.UB
        $Half = ($LoDigits.Length) / 2
        $HiMSDs = $HiDigits.Substring(0,$Half)
        for ($n = [int]$LoMSDs; $n -le $HiMSDs; ++$n) {
            $candidate = [long]"$n$n"
            if ($candidate -ge $range.LB -and $candidate -le $range.UB) {
                Write-Output "$n$n"
            }
        }
    }
}

(Get-EvenRanges | Process-EvenRanges | Measure-Object -Sum).Sum
