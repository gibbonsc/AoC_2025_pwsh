<# https://adventofcode.com/2025/day/1
  Part 2
  Count how many times a combination lock's dial passes by 0 during each spin
  Author: C Gibbons
#>
Function dial1 {
    param([int]$Position,[string]$Turn)
    $DirectionCode = $Turn.SubString(0,1)
    $Distance = [int]($Turn.SubString(1))
    if ($DirectionCode -eq "R")
    {
        $Direction = 1
    }
    else
    {
        $Direction = -1
    }
    $newPosition = $Position
    $ZeroCrossings = 0
    foreach ($n in 1..$Distance)
    {
        # I want a more efficient algorithm than this, but it works...
        $newPosition += $Direction
        $newPosition %= 100
        if ($newPosition -eq 0)
        {
            $ZeroCrossings++
        }
    }
    return $newPosition, $ZeroCrossings
}

gc ./01-input.txt | % {
    $c,$i=0,50
}{
    $dest,$increment = dial1 $i $_
    $c += $increment
    $i = $dest
}{
    $c
}