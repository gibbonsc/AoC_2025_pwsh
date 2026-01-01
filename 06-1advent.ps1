<# https://adventofcode.com/2025/day/6
  Part 1
  Arithmetic: sums and products arranged in a whitespace-separated CSV
  Author: C Gibbons
#>
$inp = Get-Content 06-input.txt
$rows = $inp.Count

$parsedRows = @()
foreach ($row in 0..($rows-2)) {
    $trimmedRow = $inp[$row].Trim()
    $parsedRow = $trimmedRow -split '\s+'
    $parsedRows += ,$parsedRow
}
$ops = $inp[$rows-1].Trim() -split '\s+'

foreach ($p in $parsedRows) {
#    $p.Count
    $p -join ','
}
#$ops.Count
$ops -join ','

[ulong[]]$subtotals = @()
for ($col=0; $col -lt $ops.Count; ++$col) {
    [ulong]$total = 0
    $op = $ops[$col]
    if ($op -eq '*') {
        $total = 1
    }
    for ($row = 0; $row -lt $parsedRows.Count; ++$row) {
        $operand = $parsedRows[$row][$col]
        if ($op -eq '*') {
            $total *= $operand
        }
        elseif ($op -eq '+') {
            $total += $operand
        }
    }
    $subtotals += ,$total
}

$subtotals -join ','
$subtotals | measure -sum
