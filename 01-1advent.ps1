<# https://adventofcode.com/2025/day/1
  Part 1
  Count how many times a combination lock's dial lands on 0 after each spin
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
    else {
        $Direction = -1
    }
    $newPosition = $Position + $Direction*$Distance
    return $newPosition
}

gc 01-input.txt | % {
    $c,$i=0,50
}{
    $i = dial1 $i $_;
    if (0 -eq ($i % 100))
    {
        $c++
    }
}{
    $c
}