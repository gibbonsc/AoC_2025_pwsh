<# https://adventofcode.com/2025/day/4
  Part 1
  How many paper-rolls scattered about a room grid can be accessed?
  Author: C Gibbons
#>

function Search-Grid {
    param(
        [string[]]$grid
    )
    # [char[][]]$testGrid = ,@('a','a','a','a','a', 'a','a','a','a','a')  # DEBUG
    # 1..9 | % { $testGrid += ,@('a','a','a','a','a', 'a','a','a','a','a') }  # DEBUG
    $forkliftReady = 0
    $rowCount = $grid.Length
    $colCount = $grid[0].Length
    foreach ($r in 0..($rowCount-1)) {
        foreach ($c in 0..($colCount-1)) {
            # $testGrid[$r][$c] = $grid[$r][$c]  # DEBUG
            if ($grid[$r][$c] -eq '.') { continue }
            $neighbors = @()
            foreach ($v in ($r-1)..($r+1)) {
                foreach ($h in ($c-1)..($c+1)) {
                    if ($v -eq $r -and $h -eq $c) { continue }
                    if ($v -ge 0 -and $v -lt $rowCount -and $h -ge 0 -and $h -lt $colCount) {
                        $neighbors += ,@($v,$h)
                    }
                }
            }
            $rollCount = 0
            foreach ($coord in $neighbors) {
                $v, $h = $coord
                $occupant = $grid[$v][$h]
                if ($occupant -eq '@') {
                    $rollCount++
                }
            }
            if ($rollCount -lt 4) {
                $forkliftReady++
                # $testGrid[$r][$c] = 'x'  # DEBUG
            }
        }
    }
    # foreach ($s in $testGrid) {  # DEBUG
    #     Write-Output ($s -join '')
    # }
    return $forkliftReady
}

# Search-Grid (Get-Content .\04-example.txt)
Search-Grid (Get-Content .\04-input.txt)
