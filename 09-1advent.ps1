<# https://adventofcode.com/2025/day/9
  Part 1
  Largest area rectangle formed by a pair among a set of points
  Author: C Gibbons
#>

class Point {
    [long]$X
    [long]$Y
    Point() {}
    Point([long]$Xp, [long]$Yp) { $this.X = $Xp; $this.Y = $Yp }
    Point([string]$s) {
        $sX, $sY = $s.Split(",")
        $this.X = [long]$sX
        $this.Y = [long]$sY
    }
    [string] ToString() { return "{0},{1}" -f $this.X, $this.Y }
}

Function Ccw {
    <#
    .SYNOPSIS
    Area of rhombus determined by three points
    Positive area if points proceed counterclockwise, negative if clockwise
    in conventional coordinate system (Y increases upward)
    #>
    param(
        [Point]$a,
        [Point]$b,
        [Point]$c
    )
    $result = ($b.X - $a.X) * ($c.Y - $a.Y) - ($b.Y - $a.Y) * ($c.X - $a.X)
    return $result
}

Function Left {
    <#
    .SYNOPSIS
    Does the path through three points make a left turn? Returns true for left turn, false for right turn or for collinear points.
    #>
    param(
        [Point]$a,
        [Point]$b,
        [Point]$c
    )
    $result = 0 -lt (Ccw $a $b $c)
    return $result
}
function Find-Lowest([Point[]]$Ps) {  # lowest vertical coordinate, highest horizontal coordinate
    $m = 0
    for ($i = 0; $i -lt $Ps.Count; $i++) {
        if ($Ps[$i].Y -lt $Ps[$m].Y -or ($Ps[$i].Y -eq $Ps[$m].Y -and $Ps[$i].X -gt $Ps[$m].X)) { $m = $i }
    }
    return $m
}

Function SubVec {
    param([Point]$P1, [Point]$P2)
    $result = [Point]::new($P1.X - $P2.X, $P1.Y - $P2.Y)
    return $result
}

Function LenSq {
    param([Point]$P)
    $result = $P.X * $P.X + $P.Y * $P.Y
    return $result
}

#$inp = Get-Content .\09-example.txt
#$inp = Get-Content .\09-1example2.txt
$inp = Get-Content .\09-input.txt
$pointCount = $inp.Count

[Point[]]$Coords = @()
foreach ($row in $inp) { $Coords += , ([Point]::new($row)) }
# Write-Output "Before swapping anchor point and copy:"
# for ($i = 0; $i -lt $pointCount; $i++) { "[{0}] {1}" -f $i, $Coords[$i] }

$anchorIndex = Find-Lowest @($Coords)
if ($anchorIndex -ne 0) {
    $Coords[0], $Coords[$anchorIndex] = 
    $Coords[$anchorIndex], $Coords[0]
}
$anchorPoint = $Coords[0]

$sortedCoords = [Point[]]::new($pointCount - 1)
[System.Array]::Copy($Coords[1..($pointCount)], $sortedCoords, $pointCount - 1)

# Write-Output "Anchor point: $anchorPoint"
# Write-Output "Before sort:"
# for ($i = 1; $i -le $sortedCoords.Count; $i++) { "[{0}] {1}" -f $i, $sortedCoords[$i-1] }

$comparison = [System.Comparison[Point]] {
    param([Point]$P1, [Point]$P2)
    $a = Ccw $P1 $P2 $anchorPoint
    #$dx1 = [long]$P1.X - [long]$anchorPoint.X
    #$dy1 = [long]$P1.Y - [long]$anchorPoint.Y
    #$dx2 = [long]$P2.X - [long]$anchorPoint.X
    #$dy2 = [long]$P2.Y - [long]$anchorPoint.Y
    #$a = ($dx1 * $dy2) - ($dy1 * $dx2)
    # apply signum to Ccw determinant (convention for functional sort comparator)
    if ($a -ne 0) { $result = [Math]::Sign($a) }
    else {
        $Len1Sq = LenSq (SubVec $P1 $anchorPoint)
        $Len2Sq = LenSq (SubVec $P2 $anchorPoint)
        # $len1Sq = $dx1 * $dx1 + $dy1 * $dy1
        # $len2Sq = $dx2 * $dx2 + $dy2 * $dy2
        $result = [Math]::Sign($len1Sq - $len2Sq)
    }
    return $result
}

[System.Array]::Sort($sortedCoords, $comparison)
$sortedCoords = @($anchorPoint) + $SortedCoords

# Write-Output " After sort:"
# for ($i = 0; $i -lt $pointCount; $i++) { "[{0}] {1}" -f $i, $sortedCoords[$i] }

Function GrahamScan {
    param( [Point[]]$Ps ) # points sorted by angle from last point
    $n = $Ps.Count
    [Point[]]$Pstack = @( $Ps[$n - 1], $Ps[0] ) # (last point and anchor point)
    $t = 1
    $i = 1
    while ( $i -lt $n ) {
        if ( (Left $Pstack[$t] $Pstack[$t - 1] $Ps[$i] )) {
            $Pstack += @($Ps[$i])
            $i++
            $t++
        }
        else {
            $Pstack = $Pstack[0..($t - 1)]
            $t--
        }
    }
    $Pstack = $Pstack[1..($t)]
    return $Pstack
}

#$culledHull = GrahamScan $sortedCoords

# Write-Output "Culled hull:"
# for ($i = 0; $i -lt $culledHull.Count; $i++) { "[{0}] {1}" -f $i, $culledHull[$i] }

# Function DrawGrid {
#     param(
#         [Point[]]$Ps
#     )
#     $Xmax = $Ymax = 0
#     foreach ($P in $Ps) {
#         if ($P.X -gt $Xmax) { $Xmax = $P.X }
#         if ($P.Y -gt $Ymax) { $Ymax = $P.Y }
#     }
#     foreach ($row in 0..($Ymax + 1)) {
#         $s = ""
#         foreach ($col in 0..($Xmax + 1)) {
#             $mark = '.'
#             foreach ($p in $Ps) {
#                 if ($P.X -eq $col -and $P.Y -eq $row) {
#                     $mark = '#'
#                     break
#                 }
#             }
#             $s += $mark
#         }
#         Write-Output $s
#     }
# }

#DrawGrid $culledHull

$maxArea = 0
$pairs = @()
foreach ($V1 in $sortedCoords) {
    #foreach ($V2 in $culledHull) {
    foreach ($V2 in $sortedCoords) {
        #if ($V2.X -lt $V1.X) { continue }
        #if ($V2.Y -lt $V2.Y) { continue }
        $area = ([Math]::Abs(($V2.X-$V1.X)+1)*([Math]::Abs($V2.Y-$V1.Y)+1))
        if ($area -ge $maxArea) {
            if ($area -gt $maxArea) {
                $pairs = @()
            }
            $pairs += , @($V1,$V2)
            $maxArea = $area
            #$maxV1,$maxV2 = $V1,$V2
        }
    }
}
#Write-Output "maxArea: $maxArea with vertices $maxV1 and $maxV2"
Write-Output "maxArea: $maxArea with vertices:"
foreach ($pair in $pairs) {
    Write-Output ("{0} and {1}" -f $pair)
}
