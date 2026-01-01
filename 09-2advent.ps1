<# https://adventofcode.com/2025/day/9
  Part 1
  Largest area rectangle formed by a pair of points
  *inscribed inside* a set of orthogonal polygon vertices
  Author: C Gibbons

  I studied my input polygon and determined that,
  even though it wasn't a convex polygon,
  it happened to be vertically monotonic: vertices were
  specified in order around the polygon, and the Y-coordinates
  were non-decreasing on one side and non-increasing on the other.
  That made it easier to partition the polygon into
  (1) a pile of horizontal rectangles and (2) a set of
  rectangles that represented the concave "dimples" inside
  polygon's convex hull but outside the polygon; then use
  those to calculate whether a rectangle formed by a pair
  of vertices was inscribed.
  
  Since then, I noticed that other competitors posted
  rendered image demos of their work on the subreddit
  https://www.reddit.com/r/adventofcode 
  which clearly show examples that are *not* monotonic
  polygons, so I may have just been lucky to achieve my
  correct answer submission. I should check my input set again.
#>

#$inp = Get-Content .\09-example.txt
#inp = Get-Content .\09-2example2.txt
$inp = Get-Content .\09-input.txt
$pointCount = $inp.Count

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
For conventional coordinate system where Y increases upward, returns
positive result if points ordered counterclockwise, negative if clockwise.
(For raster graphics where Y increases downward, returns
positive result if points ordered clockwise, negative if counterclockwise.)
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
Does the path through three points make a left turn?
Returns true for left turn, false for right turn or for collinear points.
    #>
    param(
        [Point]$a,
        [Point]$b,
        [Point]$c
    )
    $result = 0 -lt (Ccw $a $b $c)
    return $result
}

[Point[]]$Coords = @()
$Xmin, $Ymin, $Xmax, $Ymax = 99999, 99999, 0, 0
foreach ($row in $inp) {
    $P = [Point]::new($row)
    $Coords += , ($P)
    if ($Xmax -lt $P.X) { $Xmax = $P.X }
    if ($Ymax -lt $P.Y) { $Ymax = $P.Y }
    if ($Xmin -gt $P.X) { $Xmin = $P.X }
    if ($Ymin -gt $P.Y) { $Ymin = $P.Y }
}
Write-Output "Coordinates:"
for ($i = 0; $i -lt $pointCount; $i++) { "[{0}] {1}" -f $i, $Coords[$i] }
Write-Output "Extremes: $Xmin,$Ymin and $Xmax,$Ymax"

$sortedCoords = [Point[]]::new($pointCount)
[System.Array]::Copy($Coords, $sortedCoords, $pointCount)

$sortedCoords = $SortedCoords | Sort-Object Y, X

# Write-Output " After sort:"
# for ($i = 0; $i -lt $pointCount; $i++) { "[{0}] {1}" -f $i, $sortedCoords[$i] }

# partition into horizontal stripes
$StripeB = $null
$StripeT = $sortedCoords[0].Y
$StripeL = $sortedCoords[0].X
#$LSpan = $sortedCoords | Where-Object {$_.X -eq $StripeL}
$StripeR = $sortedCoords[1].X
#$RSpan = $sortedCoords | WHere-Object {$_.X -eq $StripeR}

Function NormalizeRect {
    param(
        [Point]$R1,
        [Point]$R2
    )
    # already normalized if $R1 top left, $R2 bottom right ($R1.X < $R2.X && $R1.Y < $R2.Y)
    $tl = $R1
    $br = $R2
    # adjust if not already normalized
    if ($R1.X -lt $R2.X -and $R1.Y -gt $R2.Y) {
        # $R1 bot left, $R2 top right
        $tl, $br = [Point]::new($R1.X, $R2.Y), [Point]::new($R2.X, $R1.Y)
    }
    elseif ($R1.X -gt $R2.X -and $R1.Y -lt $R2.Y) {
        # $R1 top right, $R2 bot left
        $tl, $br = [Point]::new($R2.X, $R1.Y), [Point]::new($R1.X, $R2.Y)
    }
    elseif ($R1.X -gt $R2.X -and $R1.Y -gt $R2.Y) {
        # $R1 bot right, $R2 top left
        $tl = $R2
        $br = $R1
    }
    return @($tl, $br)
}

# partition into collection of horizontal stripe rectangles
#   (not disjoint, but rather with overlapping adjacent top/bottom edges)
$Stripes = @()
for ($i = 2; $i -lt $pointCount; $i += 2) {
    $StripeB = $sortedCoords[$i].Y
    $RectTL = [Point]::new($StripeL, $StripeT)
    $RectBR = [Point]::new($StripeR, $StripeB)
    $Stripes += , @(@($RectTL, $RectBR))

    # example2 desired output:
    # 1,1  10,3
    # 1,3  7,5
    # 1,5  12,7
    # 1,7  15,9
    # 5,9  15,11
    # 3,11 15,13

    $StripeT = $StripeB  # 3
    $nextStripeL = $sortedCoords[$i].X  # 2
    $nextStripeR = $sortedCoords[$i + 1].X  # 7

    # Expand Left:
    #   next right same as previous left & next left lower than previous left;
    #   keep right samme, adjust left farther
    # Expand Right:
    #   next left same as previous right & next right higher than previous right;
    #   keep left same, adjust right farther
    # Contract Left:
    #   next left same as previous right & next left higher than previous left;
    #   keep right same, adjust left nearer
    # Contract Right:
    #   next right same as previous left & next right lower than previous right;
    #   keep left same, adjust right nearer

    if ($nextStripeL -lt $stripeL) {
        # then also $nextStripeR -eq $stripeL
        $stripeL = $nextStripeL  # expand L farther left
    }
    elseif ($nextStripeR -gt $stripeR) {
        # then also $nextStripeL -eq $stripeR
        $stripeR = $nextStripeR  # expand R farther right
    }
    elseif ($nextStripeL -gt $stripeL) {
        # then also $nextStripeL -eq $stripeR
        $stripeR = $nextStripeL  # expand L nearer righward
    }
    elseif ($nextStripeR -lt $stripeR) {
        # then also $nextStripeR -eq $stripeL
        $stripeL = $nextStripeR  # expand R nearer leftward
    }
}

#Write-Output "Rectangle partitions:"
#foreach ($pair in $Stripes) { "[TL] {0}  [BR] {1}" -f $pair[0], $pair[1] }

Function DrawGrid {
    param(
        [Point[]]$Ps,
        [Object[]]$Rects
    )
    $Xmax = $Ymax = 0
    foreach ($P in $Ps) {
        if ($P.X -gt $Xmax) { $Xmax = $P.X }
        if ($P.Y -gt $Ymax) { $Ymax = $P.Y }
    }
    foreach ($row in 0..($Ymax + 1)) {
        $s = ""
        foreach ($col in 0..($Xmax + 1)) {
            $mark = '.'
            foreach ($p in $Ps) {
                if ($P.X -eq $col -and $P.Y -eq $row) {
                    $mark = '#'
                    break
                }
            }
            foreach ($r in $Rects) {
                if ($r[0].X -le $col -and $col -le $r[1].X -and
                    $r[0].Y -le $row -and $row -le $r[1].Y -and
                    $mark -ne "#") {
                    $mark = "*"
                    break
                }
            }
            $s += $mark
        }
        Write-Output $s
    }
}

# collect rectangular areas where side boundary is concave
$RCavities = @()
for ($i = 0; $i -lt $pointCount - 1; $i++) {
    if (
        (Left $Coords[($i + 1) % $pointCount] $Coords[$i] $Coords[($i - 1) % $pointCount]) -and
        (Left $Coords[$i] $Coords[($i - 1) % $pointCount] $Coords[($i - 2) % $pointCount])
    ) {
        $RCavities += , @( NormalizeRect $Coords[($i - 2) % $pointCount] $Coords[$i] )
        $format = "Concavity: [{0},{1}] {2} {3}"
        $fargs = (($i - 2) % $pointCount), ($i), ($Coords[($i - 2) % $pointCount]), ($Coords[$i])
        Write-Output ($format -f $fargs)
    }
}

Function IsConstrained([Point]$R1, [Point]$R2) {
    # arguments: rectangle corners
    # return $true if $R1,R2 is entirely constrained within the $Stripes regions,
    #   $false otherwise

    $tl, $br = NormalizeRect $R1 $R2
    $tr = [Point]::new($R2.X, $R1.Y)
    $bl = [Point]::new($R1.X, $R2.Y)

    # data specific artifact:
    # ex: (5265,67245), (94904,48302)
    # check to see if rectangle intersects any discovered nonconvex cavities
    foreach ($C in $RCavities) {
        $ctl, $cbr = $C
        $maxE = [Math]::Max($tl.X, $ctl.X)
        $minW = [Math]::Min($br.X, $cbr.X)
        $maxN = [Math]::Max($tl.Y, $ctl.Y)
        $minS = [Math]::Min($br.Y, $cbr.Y)
        if (
            ($maxE -lt $minW) -and ($maxN -lt $minS)
        ) {
            $format = "{0} {1} overlaps concavity {2} {3}"
            $fargs = $R1, $R2, $ctl, $cbr
            Write-Host ($format -f $fargs)
            return $false
        }
    }

    # presume all four corners outside of constraints ($Stripes regions)
    $tlIn = $blIn = $brIn = $trIn = $false
    # then search for counterexamples until all four are found
    foreach ($RStripe in $Stripes) {
        $RStl, $RSbr = $RStripe[0], $RStripe[1]
        if ($RStl.X -le $tl.X -and $tl.X -le $RSbr.X -and
            $RStl.Y -le $tl.Y -and $tl.Y -le $RSbr.Y) {
            $tlIn = $true
        } 
        if ($RStl.X -le $bl.X -and $bl.X -le $RSbr.X -and
            $RStl.Y -le $bl.Y -and $bl.Y -le $RSbr.Y) {
            $blIn = $true
        } 
        if ($RStl.X -le $br.X -and $br.X -le $RSbr.X -and
            $RStl.Y -le $br.Y -and $br.Y -le $RSbr.Y) {
            $brIn = $true
        } 
        if ($RStl.X -le $tr.X -and $tr.X -le $RSbr.X -and
            $RStl.Y -le $tr.Y -and $tr.Y -le $RSbr.Y) {
            $trIn = $true
        }
        if ($tlIn -and $blIn -and $brIn -and $trIn) {
            return $true
        }
    }
    return $false
}

$maxArea = 0
$pairs = @()
for ($j = 0; $j -lt $pointCount - 1; $j++) {
    $V1 = $Coords[$j]
    for ($k = $j + 1; $k -lt $pointCount; $k++) {
        $V2 = $Coords[$k]
        # check if constrained
        if (-not (IsConstrained $V1 $V2)) { continue }
        $area = ([Math]::Abs($V2.X - $V1.X) + 1) * ([Math]::Abs($V2.Y - $V1.Y) + 1)
        if ($area -ge $maxArea) {
            if ($area -gt $maxArea) {
                $pairs = @()
            }
            $pairs += , @($V1, $V2)
            $maxArea = $area
        }
    }
}

#DrawGrid $sortedCoords $Stripes

#Write-Output "maxArea: $maxArea with vertices $maxV1 and $maxV2"
Write-Output "maxArea: $maxArea with vertices:"
foreach ($pair in $pairs) {
    Write-Output ("{0} and {1}" -f $pair)
}
