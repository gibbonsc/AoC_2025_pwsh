<# https://adventofcode.com/2025/day/4
  Part 2
  How many rolls may not only be accessed but also removed?
  (Iterate, because removing a roll may free up previously inaccessible rolls)
  Author: C Gibbons
#>

$grid = Get-Content .\04-input.txt
$rowCount = $grid.Length
$colCount = $grid[0].Length
[char[][]]$xGrid = , (@('a') * $colCount)
1..($rowCount - 1) | Foreach-Object { $xGrid += , (@('a') * $colCount) }
foreach ($r in 0..($rowCount - 1)) {
    foreach ($c in 0..($colCount - 1)) {
        $xGrid[$r][$c] = $grid[$r][$c]
    }
}
foreach ($s in $xGrid) {
    Write-Output ($s -join '')
}
Write-Output ''
#return

function Search-Grid {
    # modifies xGrid as it searches
    $forkliftReady = 0
    $rowCount = $xGrid.Length
    $colCount = $xGrid[0].Length
    foreach ($r in 0..($rowCount - 1)) {
        foreach ($c in 0..($colCount - 1)) {
            if ($xGrid[$r][$c] -eq '.') { continue }
            $neighbors = @()
            foreach ($v in ($r - 1)..($r + 1)) {
                foreach ($h in ($c - 1)..($c + 1)) {
                    if ($v -eq $r -and $h -eq $c) { continue }
                    if ($v -ge 0 -and $v -lt $rowCount -and $h -ge 0 -and $h -lt $colCount) {
                        $neighbors += , @($v, $h)
                    }
                }
            }
            $rollCount = 0
            foreach ($coord in $neighbors) {
                $v, $h = $coord
                $occupant = $xGrid[$v][$h]
                if ($occupant -eq '@' -or $occupant -eq 'x') {
                    $rollCount++
                }
            }
            if ($rollCount -lt 4) {
                $forkliftReady++
                $xGrid[$r][$c] = 'x'
            }
        }
    }
    return $forkliftReady
}

$count = $total = 0
do {
    $count = Search-Grid (Get-Content .\04-example.txt)
    $total += $count
    foreach ($s in $xGrid) {
        Write-Output ($s -join '')
    }
    Write-Output $count
    foreach ($r in 0..($rowCount - 1)) {
        foreach ($c in 0..($colCount - 1)) {
            if ($xGrid[$r][$c] -eq 'x') {
                $xGrid[$r][$c] = '.'
            }
        }
    }
    foreach ($s in $xGrid) {
        Write-Output ($s -join '')
    }
    Write-Output ''
} while ($count -ne 0)
Write-Output "TOTAL: $total"
