<# https://adventofcode.com/2025/day/7
  Part 2
  count "timeline paths" down the grid of beam splitters.
  My ugly algorithm is O(n^3), but my friend said he solved this
    "bottom-up" in linear time -- that's cool.
  Author: C Gibbons
#>

# class PathTrace {
#     [int[]]$Steps

#     PathTrace() { $this.Steps = @() }
#     PathTrace([PathTrace] $p) { $this.Steps = $p.Steps.Clone() }

#     [void] AddStep([int]$s) { $this.Steps += , $s }
#     [string] ToString() { return "[PathTrace] " + ($this.Steps -join ',') }

#     [bool] SameAs([PathTrace]$p) {
#         $result = $true
#         if ($p.Steps.Count -ne $this.Steps.Count) {
#             $result = $false
#         }
#         else {
#             for ($i=0; $i -lt $p.Steps.Count; $i++) {
#                 if ($p.Steps[$i] -ne $this.Steps[$i]) {
#                     $result=$false
#                     break
#                 }
#             }
#         }
#         return $result
#     }
# }

#$inp = Get-Content .\07-example.txt
$inp = Get-Content .\07-input.txt
$rows = $inp.Count

$Beams = @()
$PathTallies = 0..($inp[0].Length - 1) | Foreach-Object { 0 } 
$splitCount = 0

# find first beam
$start = $inp[0].IndexOf("S")
$Beams += , $start
$PathTallies[$start] = 1

# traverse input looking for splits
for ($row = 2; $row -lt $rows; $row += 2) {
    foreach ($b in $Beams) {
        if ($inp[$row][$b] -eq '^') {
            $splitCount++

            $tally = $PathTallies[$b]
            $PathTallies[$b] = 0

            $Beams = @( $Beams | Where-Object { $_ -ne $b } )
            if ($Beams -notcontains ($b - 1)) {
                $Beams += , ($b - 1)
                $PathTallies[$b - 1] = $tally
            }
            else {
                $PathTallies[$b - 1] += $tally
            }
            if ($Beams -notcontains ($b + 1)) {
                $Beams += , ($b + 1)
                $PathTallies[$b + 1] = $tally
            }
            else {
                $PathTallies[$b + 1] += $tally
            }
        }
    }
}
Write-Output $splitCount
Write-Output ($PathTallies -join ' + ')
$PathTallies | Measure-Object -Sum