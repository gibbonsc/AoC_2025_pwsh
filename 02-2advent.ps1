<# https://adventofcode.com/2025/day/2
  Part 2
  Discover and sum invalid ID numbers
  (IDs that consist of numeral sequences repeated 2 or more times)
  Author: C Gibbons
#>

# collect intervals
class Interval {
    [int128]$LB
    [int128]$UB

    Interval($l,$u) { $this.LB = $l; $this.UB = $u }
    [string] ToString() {
        $result = "Interval({0},{1})" -f $this.LB,$this.UB
        return $result
    }
}

# function eratosthenes ($n) {
#     #  https://rosettacode.org/wiki/Sieve_of_Eratosthenes#PowerShell
#     if($n -lt 1){
#         Write-Warning "$n is less than 1"
#     } else {
#         $prime = @(1..($n+1) | Foreach-Object {$true})
#         $prime[1] = $false
#         $m = [Math]::Floor([Math]::Sqrt($n))
#         for($i = 2; $i -le $m; $i++) {
#             if($prime[$i]) {
#                 for($j = $i*$i; $j -le $n; $j += $i) {
#                     $prime[$j] = $false
#                 }
#             }
#         }
#         1..($n-1) | Where-Object {$prime[$_]}
#     }
# }

# function Get-PrimeDivisors {
#     param(
#         [Parameter(Mandatory)]
#         [int128]$Dividend
#     )

#     $Divisors = @([int128]1)
#     if ($Dividend -eq 1) {return $Divisors}
#     $Primes = eratosthenes([ulong]$Dividend) # $Primes will contain just [int] objects
#     foreach ($i in $Primes) {
#         $q = $Dividend / [int128]$i
#         if ($q -eq [math]::floor([ulong]$q)){ # no floor overload for [int128]
#             $Divisors += [int128]$i
#         }
#     }
#     return $Divisors
# }

function Get-Divisors {
    param(
        [Parameter(Mandatory)]
        [int]$Dividend
    )

    $Divisors = @()
    if ($Dividend -eq 1) {return $Divisors}
    # cast to ulong because .. operator needs [System.IConvertible], which [int128] fails.
    $Sequence = 1..([ulong]$Dividend-1)
    foreach ($i in $Sequence) {
        $q = $Dividend / $i
        if ($q -eq [math]::floor($q)){ # no floor overload for [int128]
            $Divisors += $i
        }
    }
    return $Divisors
}


# a brief test of Get-Divisors
#2..10 | Foreach-Object {(Get-Divisors($_)) -join ','}
#return

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
            $LB,$UB = [int128]$LBText,[int128]$UBText
            $Interval = [Interval]::new($LB,$UB)
            $IntervalList += $Interval
        }
        return $IntervalList
    }
}

function Search-Interval {
    param(
        [Parameter(ValueFromPipeline)]
        [Interval]$Range
    )
    #Write-Output "DEBUG: `t$($Range.ToString())"

    #how many decimal digits in the lower bound?
    $LowerBound = $Range.LB
    $LDigits = [math]::floor([math]::log10($LowerBound)) + 1
    #if only one digit, shift bound up to first two digit number
    if ($LDigits -eq 1) {$LDigits = 2; $LowerBound = 10}
    $LowerDivisors = Get-Divisors($LDigits)
    #how many decimal digits in the upper bound?
    $UpperBound = $Range.UB
    $UDigits = [math]::floor([math]::log10($UpperBound)) + 1
    # if UDigits same as LDigits, process entire interval at once
    if ($UDigits -eq $LDigits) {
        foreach ($Span in @($LowerDivisors)){
            $Repeats = $LDigits / $Span
            $LPrefix = [int128](([string]$LowerBound).Substring(0,$Span))
            $UPrefix = [int128](([string]$UpperBound).Substring(0,$Span))
            for ($p=$LPrefix; $p -le $UPrefix; $p += 1){
                $candidate = [int128](([string]$p) * $Repeats)
                if ($candidate -lt $LowerBound) {continue}
                if ($candidate -gt $UpperBound) {continue}
                Write-Output $candidate
            }
        }
    }
    # if UDigits is greater than LDigits, partition at power of ten
    #   (won't work if interval includes more than one power of ten)
    else {
        $MidBound = [int128][math]::pow(10,$UDigits-1) - 1
        foreach ($Span in @($LowerDivisors)){
            $Repeats = $LDigits / $Span
            $LPrefix = [int128](([string]$LowerBound).Substring(0,$Span))
            $UPrefix = [int128](([string]$MidBound).Substring(0,$Span))
            for ($p=$LPrefix; $p -le $UPrefix; $p += 1){
                $candidate = [int128](([string]$p) * $Repeats)
                if ($candidate -lt $LowerBound) {continue}
                if ($candidate -gt $MidBound) {continue}
                Write-Output $candidate
            }
        }
        $MidBound += 1
        $UpperDivisors = Get-Divisors($UDigits)
        foreach ($Span in @($UpperDivisors)){
            $Repeats = $UDigits / $Span
            $LPrefix = [int128](([string]$MidBound).Substring(0,$Span))
            $UPrefix = [int128](([string]$UpperBound).Substring(0,$Span))
            for ($p=$LPrefix; $p -le $UPrefix; $p += 1){
                $candidate = [int128](([string]$p) * $Repeats)
                if ($candidate -lt $MidBound) {continue}
                if ($candidate -gt $UpperBound) {continue}
                Write-Output $candidate
            }
        }
    }
}

$is = gc ./02-input.txt | Read-Intervals  #| Sort-Object -Property UB
$ia = $is | % { Search-Interval $_ } | Sort-Object -Unique
$ia | Measure-Object -Sum

# incorrect attempt 1 (with Get-PrimeDivisors): 33505554546 is too low

# function Get-EvenRanges {
#     $ranges = (Get-Content .\input2-1.txt | Read-Intervals | Sort-Object -Property UB)
#     #$rangeMax = 0
#     foreach ($range in $ranges) {
#         # how many decimal digits in the lower bound?
#         $LowerBound = $range.LB
#         $LDigits = [math]::floor([math]::log10($range.LB)) + 1
#         # if odd number of digits, shift bound up to next power of 10
#         if (1 -eq [int]$LDigits % 2) {
#             $LowerBound = [long][math]::pow(10,$LDigits)
#         }
#         # how many decimal digits in the upper bound?
#         $UpperBound = $range.UB
#         $UDigits = [math]::floor([math]::log10($range.UB)) + 1
#         # if odd number of digits, shift bound down past previous power of 10
#         if (1 -eq [int]$UDigits % 2) {
#             $UpperBound = [long][math]::pow(10,$Udigits-1) - 1
#         }
#         # if both bounds had the same odd number of digits, skip that range
#         if ($LowerBound -le $UpperBound) {
#             $Interval = [Interval]::new($LowerBound,$UpperBound)
#             Write-Output $Interval
#         }
#     }
# }

# function Process-EvenRanges {
#     param(
#         [Parameter(ValueFromPipeline)]
#         [Interval]$range
#     )
#     process {
#         $LoDigits = [string]$range.LB
#         $Half = ($LoDigits.Length) / 2
#         $LoMSDs = $LoDigits.Substring(0,$Half)
#         $HiDigits = [string]$range.UB
#         $Half = ($LoDigits.Length) / 2
#         $HiMSDs = $HiDigits.Substring(0,$Half)
#         for ($n = [int]$LoMSDs; $n -le $HiMSDs; ++$n) {
#             $candidate = [long]"$n$n"
#             if ($candidate -ge $range.LB -and $candidate -le $range.UB) {
#                 Write-Output "$n$n"
#             }
#         }
#     }
# }

#Get-EvenRanges | Process-EvenRanges
