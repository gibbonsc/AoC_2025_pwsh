<# https://adventofcode.com/2025/day/3
  Part 2
  Discover and sum maximum "joltage" values.
  (specified by twelve ordered but not necessarily adjacent base-ten digits)
  Author: C Gibbons
#>

function Get-Digits {
    param(
        [string]$S
    )
    $chars = [uint[]][char[]]$S
    [uint[]]$result = @()
    foreach ($c in $chars) {
        $result += $c - [uint][char]'0'
    }
    return $result
}

function Merge-TwelveDigits {
    if ($args.Count -ne 12) {Write-Warning "expected 12 arguments, got $($args.Count)"}
    [ulong]$r = 0
    $p = 1000000000000
    foreach ($d in $args) {
        $p /= 10
        $r += $d * $p
    }
    return $r
}

function Find-HighestTwelveDigitNumeral
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$DigitString
    )
    $Digits = Get-Digits $DigitString
    $BestIndexes = 0..11  # start with first 12 digits
    $TwelveDigits = $Digits[$BestIndexes]
    $Best12 = Merge-TwelveDigits @TwelveDigits 
    foreach ($d in 12..($Digits.Length - 1)) {
        $ThirteenIndexes = $BestIndexes + $d
        foreach ($Duty in 0..11) {
            $ix = -1
            $ThirteenCulled = foreach ($x in $ThirteenIndexes) {
                $ix++
                if ($ix -ne $Duty) { $x }
            }
            $TwelveDigits = $Digits[$ThirteenCulled]
            $Candidate = Merge-TwelveDigits @TwelveDigits
            if ($Candidate -gt $Best12) {
                $BestIndexes = $ThirteenCulled
                $Best12 = $Candidate
            }
        }
    }
    return $Best12
}

$joltages = Get-Content .\03-input.txt | Foreach-Object { Find-HighestTwelveDigitNumeral $_ }
$joltages | Measure-Object -Sum