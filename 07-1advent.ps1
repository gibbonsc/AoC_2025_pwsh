<# https://adventofcode.com/2025/day/7
  Part 1
  trace "beam splitters" down a grid
  Author: C Gibbons
#>

$inp = Get-Content .\07-input.txt
$rows = $inp.Count

$Beams = @()
#$Splits = @()
$splitCount = 0

# find first beam
$start = $inp[0].IndexOf("S")
$Beams += , $start

# traverse input looking for splits
for ($row = 2; $row -lt $rows; $row += 2) {
    foreach ($b in $Beams) {
        if ($inp[$row][$b] -eq '^') {
            $splitCount++
            $Beams = @( $Beams | Where-Object { $_ -ne $b } )
            if ($Beams -notcontains ($b - 1)) {
                $Beams += , ($b - 1)
            }
            if ($Beams -notcontains ($b + 1)) {
                $Beams += , ($b + 1)
            }
        }
    }
}
Write-Output $splitCount
