<# https://adventofcode.com/2025/day/6
  Part 2
  Arithmetic: sums and products arranged in a whitespace-separated CSV
  (different numeral orientation)
  Author: C Gibbons
#>

$inp = Get-Content 06-input.txt
$rows = $inp.Count - 1

# foreach ($row in 0..($rows - 2)) {
#     $inp[$row].Length
# }

$ops = $inp[$rows]
# $ops.Length

# separate problem grids by vertical columns of spaces
$problemGrids = @()
$spacePile = ' ' * $rows + ' '
$c = $ops.Length - 1
do {
    $reach = 1
    do {
        $reach += 1
        $pile = ''
        for ($r = $rows; $r -ge 0; --$r) {
            if (($c - $reach) -ge 0) {
                $pile += $inp[$r][$c - $reach]
            }
            else {
                $pile += ' '
            }
        }
    } while ($pile -ne $spacePile)
    $boxL = $c - $reach + 1
    $problemGrid = @()
    foreach ($row in $inp) {
        $problemGrid += ,$row.Substring($boxL,$reach)
    }
    $problemGrids += ,$problemGrid
    $c -= ($reach + 1)
} while ($c -ge 0)

[ulong[]]$subtotals = @()
foreach ($problemGrid in $problemGrids) {
    $opChar = $problemGrid[$rows][0]
    $numOperands = $problemGrid[0].Length
    $operands = @(0) * $numOperands
    $magnitudes = @(1) * $numOperands
    for ($r = $rows - 1; $r -ge 0; --$r) {
        for ($pile = $numOperands - 1; $pile -ge 0; --$pile) {
            $digit = $problemGrid[$r][$pile]
            if ($digit -eq ' ') {
                continue
            }
            else {
                $digit -= [int][char]'0'
                $operands[$pile] += $magnitudes[$pile] * [int]$digit
                $magnitudes[$pile] *= 10
            }
        }
    }
    $aggregate = 0
    if ($opchar -eq '*') {
        $aggregate = 1
        foreach ($operand in $operands) {
            $aggregate *= $operand
        }
    }
    elseif ($opchar -eq '+')
    {
        foreach ($operand in $operands) {
            $aggregate += $operand
        }
    }
    $subtotals = ,$aggregate + $subtotals
}

$subtotals | measure -sum
return

# for ($c = $ops.Length - 1; $c -gt 0; $c -= 4) {
#     $opchar = $ops[$c - 2]
#     $operands = 0, 0, 0
#     $magnitudes = 1, 1, 1
#     for ($r = $rows - 1; $r -ge 0; --$r) {
#         for ($pile = 3 - 1; $pile -ge 0; --$pile) {
#             $digit = $inp[$r][$c-$pile]
#             if ($digit -eq ' ') {
#                 continue
#             }
#             else {
#                 $digit -= [int][char]'0'
#                 $operands[$pile] += $magnitudes[$pile] * [int]$digit
#                 $magnitudes[$pile] *= 10
#             }
#         }
#     }
#     $triple = 0
#     if ($opchar -eq '*') {
#         $triple = $operands[0] * $operands[1] * $operands[2]
#     }
#     elseif ($opchar -eq '+')
#     {
#         $triple = $operands[0] + $operands[1] + $operands[2]
#     }
#     $subtotals = ,$triple + $subtotals
# }

#foreach ($p in $parsedRows) {
#    $p.Count
#    $p -join ','
#}
#$ops.Count
#$ops -join ','

# [ulong[]]$subtotals = @()
# for ($col=0; $col -lt $ops.Count; ++$col) {
#     [ulong]$total = 0
#     $op = $ops[$col]
#     if ($op -eq '*') {
#         $total = 1
#     }
#     for ($row = 0; $row -lt $parsedRows.Count; ++$row) {
#         $operand = $parsedRows[$row][$col]
#         if ($op -eq '*') {
#             $total *= $operand
#         }
#         elseif ($op -eq '+') {
#             $total += $operand
#         }
#     }
#     $subtotals += ,$total
# }

# $subtotals -join ','