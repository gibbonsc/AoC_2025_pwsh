<# https://adventofcode.com/2025/day/3
  Part 1
  Discover and sum maximum "joltage" values.
  (specified by two ordered but not necessarily adjacent base-ten digits)
  Author: C Gibbons
#>
function Get-Digits {
    param(
        [Parameter(ValueFromPipeline)]
        [string]$S
    )
    $chars = [uint[]][char[]]$S
    [uint[]]$result = @()
    foreach ($c in $chars) {
        $result += $c - [uint][char]'0'
    }
    return $result
}

function Find-LargestDigitIndex
{
    param(
        [Parameter(Mandatory=$true)]
        [uint[]]$Digits,
        [int]$LowIndex,
        [int]$HighIndex
    )
    if (0 -eq $LowIndex -and 0 -eq $HighIndex) {
        $HighIndex = $Digits.Length - 1
    }
    $max = $maxIndex = 0
    for ($i = $LowIndex; $i -le $HighIndex; ++$i) {
        if ($Digits[$i] -gt $max) {
            $max = $Digits[$i]
            $maxIndex = $i
        }
    }
    return $maxIndex
}

function Find-LargestPair
{
    param(
        [Parameter(ValueFromPipeline)]
        [string]$DigitString
    )
    $Digits = $DigitString | Get-Digits
    $HighestIndex = Find-LargestDigitIndex $Digits
    if ($HighestIndex -eq $Digits.Length - 1) {
        $NextHighestIndex = Find-LargestDigitIndex $Digits 0 ($HighestIndex - 1) 
        return $Digits[$NextHighestIndex] * 10 + $Digits[$HighestIndex]
    }
    else {
        $NextHighestIndex = Find-LargestDigitIndex $Digits ($HighestIndex + 1) ($Digits.Length - 1)
        return $Digits[$HighestIndex] * 10 + $Digits[$NextHighestIndex]
    }
}

$joltages = Get-Content .\03-input.txt | Foreach-Object { $_ | Find-LargestPair }
$joltages | Measure-Object -Sum