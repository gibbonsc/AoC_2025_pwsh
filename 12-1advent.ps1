<# https://adventofcode.com/2025/day/12
   part 1 (part 2 just consists of achieving the other 23 stars)
   Explore feasibility of successfully tesselating
     a given collection of 3x3 shapes inside a given rectangle
   Author: C Gibbons
#>

# Import-Module -Name .\StreamTests.psm1
#  (forget it, that module doesn't work)

#$inp = Get-Content .\12-1example1.txt
$inp = Get-Content .\12-input.txt
$rows = $inp.Count
$ShapeCount = 6
$EnvelopeCount = $rows - ($ShapeCount * 5)

#. ./OctalHashDots.ps1
#  (forget it, those functions aren't necessary after all)

# Convert a "jagged" array of arrays of integers into a string suitable for display
function Format-Matrix {
    param(
        [Object[][]]$M
    )
    $r = ''
    foreach ($row in $M) {
        $r += "["
        foreach ($item in $row) { $r += ' ' + $item }
        $r += " ]`n"
    }
    $r
}

# parse the first part of the input into a jagged array
#   first index: that particular 3x3 shape as an array of 9-bit binary sprites
#   second index: one of the possible rotations or flips of that shape
# use LSB bit ordering (unit bit left, 2's bit middle, 4's bit right)
function Parse-3x3Shapes {
    [CmdletBinding()][OutputType([int[][]])]param([string[]]$inp, [int]$ShapeCount)
    [int[][]] $result = @()
    for ($i = 0; $i -lt $ShapeCount; $i++) {
        $patterns = @($inp[$i * 5 + 1], $inp[$i * 5 + 2], $inp[$i * 5 + 3])
        $bits = @(
            (@(
                (($patterns[0][0] -eq '.')?0:1),
                (($patterns[0][1] -eq '.')?0:1),
                (($patterns[0][2] -eq '.')?0:1)
            )),
            (@(
                (($patterns[1][0] -eq '.')?0:1),
                (($patterns[1][1] -eq '.')?0:1),
                (($patterns[1][2] -eq '.')?0:1)
            )),
            (@(
                (($patterns[2][0] -eq '.')?0:1),
                (($patterns[2][1] -eq '.')?0:1),
                (($patterns[2][2] -eq '.')?0:1)
            ))
        )
        Write-Debug ("`n$($patterns[0])`n$($patterns[1])`n$($patterns[2])`n" + (Format-Matrix $bits))
        $Powers2 = @(
            1, 2, (2 * 2), (2 * 2 * 2), (2 * 2 * 2 * 2), (2 * 2 * 2 * 2 * 2),
            (2 * 2 * 2 * 2 * 2 * 2), (2 * 2 * 2 * 2 * 2 * 2 * 2),
            (2 * 2 * 2 * 2 * 2 * 2 * 2 * 2)
        )
        $Pack9Bits = (
            $bits[0][0] * $Powers2[0] + $bits[0][1] * $Powers2[1] + $bits[0][2] * $Powers2[2] +
            $bits[1][0] * $Powers2[3] + $bits[1][1] * $Powers2[4] + $bits[1][2] * $Powers2[5] +
            $bits[2][0] * $Powers2[6] + $bits[2][1] * $Powers2[7] + $bits[2][2] * $Powers2[8]
        )
        [int[]]$D8 = @(
            # original pattern
            $Pack9Bits,
            # rotated top-right 90
            ($bits[2][0] * $Powers2[0] + $bits[1][0] * $Powers2[1] + $bits[0][0] * $Powers2[2] +
            $bits[2][1] * $Powers2[3] + $bits[1][1] * $Powers2[4] + $bits[0][1] * $Powers2[5] +
            $bits[2][2] * $Powers2[6] + $bits[1][2] * $Powers2[7] + $bits[0][2] * $Powers2[8]),
            # rotated 180
            ($bits[2][2] * $Powers2[0] + $bits[2][1] * $Powers2[1] + $bits[2][0] * $Powers2[2] +
            $bits[1][2] * $Powers2[3] + $bits[1][1] * $Powers2[4] + $bits[1][0] * $Powers2[5] +
            $bits[0][2] * $Powers2[6] + $bits[0][1] * $Powers2[7] + $bits[0][0] * $Powers2[8]),
            # rotated top-left 90
            ($bits[0][2] * $Powers2[0] + $bits[1][2] * $Powers2[1] + $bits[2][2] * $Powers2[2] +
            $bits[0][1] * $Powers2[3] + $bits[1][1] * $Powers2[4] + $bits[2][1] * $Powers2[5] +
            $bits[0][0] * $Powers2[6] + $bits[1][0] * $Powers2[7] + $bits[2][0] * $Powers2[8]),
            # flip on horizontal axis -
            ($bits[2][0] * $Powers2[0] + $bits[2][1] * $Powers2[1] + $bits[2][2] * $Powers2[2] +
            $bits[1][0] * $Powers2[3] + $bits[1][1] * $Powers2[4] + $bits[1][2] * $Powers2[5] +
            $bits[0][0] * $Powers2[6] + $bits[0][1] * $Powers2[7] + $bits[0][2] * $Powers2[8]),
            # transpose \ 
            ($bits[0][0] * $Powers2[0] + $bits[1][0] * $Powers2[1] + $bits[2][0] * $Powers2[2] +
            $bits[0][1] * $Powers2[3] + $bits[1][1] * $Powers2[4] + $bits[2][1] * $Powers2[5] +
            $bits[0][2] * $Powers2[6] + $bits[1][2] * $Powers2[7] + $bits[2][2] * $Powers2[8]),
            # flip on vertial axis |
            ($bits[0][2] * $Powers2[0] + $bits[0][1] * $Powers2[1] + $bits[0][0] * $Powers2[2] +
            $bits[1][2] * $Powers2[3] + $bits[1][1] * $Powers2[4] + $bits[1][0] * $Powers2[5] +
            $bits[2][2] * $Powers2[6] + $bits[2][1] * $Powers2[7] + $bits[2][0] * $Powers2[8]),
            # slash-flip /
            ($bits[2][2] * $Powers2[0] + $bits[1][2] * $Powers2[1] + $bits[0][2] * $Powers2[2] +
            $bits[2][1] * $Powers2[3] + $bits[1][1] * $Powers2[4] + $bits[0][1] * $Powers2[5] +
            $bits[2][0] * $Powers2[6] + $bits[1][0] * $Powers2[7] + $bits[0][0] * $Powers2[8])
        ) | Sort-Object -Unique
        $result += , $D8
    }
    Write-Output -NoEnumerate $result
}

# count the 1 bits in a 9-bit binary representation of a 3x3 sprite
function Measure-ShapeBits {
    [CmdletBinding()]param([int]$o)
    $r = 0
    foreach ($p in 0..8) {
        $a = $o -shr $p
        $b = $a -band 1
        if ($b -eq 1) { $r++ }
    }
    $r
}

# Get 3-line string representation of the 9-bits of a 3x3 sprite 
function Format-3x3Bits {
    [CmdletBinding()]param([Parameter(Mandatory, ValueFromPipeline)][int]$o)
    $r = ''
    foreach ($p in 0..8) {
        $a = $o -shr $p
        $b = $a -band 1
        $c = $b ? '#' : '.'
        $r += $c
        if (2 -eq ($p % 3)) { $r += "`n" }
    }
    $r
}

# Get 3-line string representations of all possible orientations of a 3x3 sprite
function Format-3x3OrientationsRow {
    [CmdletBinding()]param([Parameter(Mandatory, ValueFromPipeline)][int[]]$s)
    $r = ''
    foreach ($line in 0..2) {
        for ($i = 0; $i -lt $s.Count; $i++) {
            if ($line -eq 0 ) { $r += " ${i}: " } else { $r += "    " }
            $o = $s[$i]
            foreach ($p in 0..2) {
                $a = $o -shr ($p + $line * 3)
                $b = $a -band 1
                $c = $b ? '#' : '.'
                $r += $c
            }
        }
        $r += "`n"
    }
    $r
}

# sum of pairwise multiples of elements of integer arrays
function Get-DotProduct {
    [CmdletBinding()]param([int[]]$a, [int[]]$b)
    if ($a.Count -ne $b.Count) { throw "Unequal array lengths" }
    $r = 0
    for ($i = 0; $i -lt $a.Count; $i++) { $r += ($a[$i] * $b[$i]) }
    $r
}

# parse the second part of the input into an array of PSCustomObject items
#  Envelope: the dimensions (column-major order) of the enclosure
#  WorkOrder: how many of each shape must be packed into the enclosure
function Parse-Packings {
    [CmdletBinding()]param([string[]]$inp, [int]$EnvelopeCount, [int[][]]$ParsedShapes)
    $BitCounts = [int[]]::new($ParsedShapes.Count)
    for ($i = 0; $i -lt $ParsedShapes.Count; $i++) {
        $BitCounts[$i] = Measure-ShapeBits $ParsedShapes[$i][0]
    }
    $Packings = @()
    for ($i = 0; $i -lt $EnvelopeCount; $i++) {
        $row = $ShapeCount * 5 + $i
        $PackSpec = $inp[$row]
        $Dimensions, $CargoManifest = $PackSpec.Split(': ')
        [int[]]$Envelope = $Dimensions.Split('x')
        [int[]]$WorkOrder = $CargoManifest.Split(' ')

        # check for and exclude packing problems guaranteed to be impossible to solve
        $EnvelopeArea = $Envelope[0] * $Envelope[1]
        $AggregateWOArea = Get-DotProduct $BitCounts $WorkOrder
        if ($EnvelopeArea -ge $AggregateWOArea) {
            $Packings += [PSCustomObject]@{
                Envelope  = $Envelope
                WorkOrder = $WorkOrder
            } 
        }
    }
    Write-Output -NoEnumerate $Packings
}

# count how many individual pixels would be consumed by a packing problem's WorkOrder
function Measure-Cells {
    [CmdletBinding()]param([Parameter(Mandatory, ValueFromPipeline)]$Packing)
    $Envelope = $Packing.Envelope
    $Envelope[0] * $Envelope[1]  # (Write-Output)
    $WorkOrder = $Packing.WorkOrder
    $WorkOrder[0] * 5 + $WorkOrder[1] * 7 + $WorkOrder[2] * 7 +
    $WorkOrder[3] * 7 + $WorkOrder[4] * 6 + $WorkOrder[5] * 7  # (Write-Output)
}

# convert an array of 64-bit integers (up to $MaxCols bits)
#   into a collection of strings suitable for display
# use LSB bit ordering: (unit bit leftmost, 2's bit , 4's bit, etc. ... 2^($MaxCols-1) bit rightmost)
function Format-Grid {
    [CmdletBinding()]param(
        [long[]]$GridArray,
        [int]$MaxCols
    )
    # $maxCols = (
    #     $GridArray |
    #     Foreach-Object { [Math]::Ceiling([Math]::Log($_,2)) } |
    #     Measure-Object -Maximum
    # ).Maximum  # doesn't work; too small if rightmost columns are entirely zero bits.
    $r = ''
    foreach ($row in $GridArray) {
        $line = '|'
        $bits = $row
        while ($bits -gt 0) {
            $b = $bits -band 1
            $line += ($b ? '#' : '.')
            $bits = $bits -shr 1
        }
        $line += ("." * (1 + $MaxCols - $line.Length) + "|`n")
        $r += $line
    }
    $r
}

# create a new enclosure grid with all bits turned on to 1.
function Get-Grid {
    [CmdletBinding()]param([int[]]$EnvelopeDimensions)
    $cols, $rows = $EnvelopeDimensions
    [long]$rowbits = (1..$cols | ForEach-Object { [long]$p = 1 } { $p *= 2 } { $p }) - 1
    $Grid = @($rowbits) * $rows
    $Grid
}

# Given a grid and a shape with coordinates inside that grid,
#   see if a transformed 3x3 "sprite" overlaps any bits
#   in the grid that were already been turned off to 0
function Test-3x3Collision {
    [CmdletBinding()]param([long[]]$Grid, [int]$cols, [int]$ShapeBits, [int]$r, [int]$c)
    $DebugReq = ($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters['Debug'])
    if ($r -ge ($Grid.Count - 2) -or $c -ge ($cols - 2) -or $r -lt 0 -or $c -lt 0) {
        return $true  # Beyond edges of grid
    }
    $ShapeShift = @(
        ($ShapeBits -band 0b111) -shl $c  # top row moved right $c bits
        ($ShapeBits -band 0b111000) -shr 3 -shl $c  # middle row
        ($ShapeBits -band 0b111000000) -shr 6 -shl $c  # bottom row
    )
    if ($DebugReq) {
        $GridCopy = [long[]]::new($Grid.Count)
        [System.Array]::Copy($Grid, $GridCopy, $Grid.Count)
        $GridCopy[$r  ] = ($ShapeShift[0] -bxor $Grid[$r  ])
        $GridCopy[$r + 1] = ($ShapeShift[1] -bxor $Grid[$r + 1])
        $GridCopy[$r + 2] = ($ShapeShift[2] -bxor $Grid[$r + 2])
        Write-Debug ("`n" + (Format-Grid $GridCopy $cols))
    }
    if (
        $Grid[$r  ] -eq ($ShapeShift[0] -band $Grid[$r  ]) -and
        $Grid[$r + 1] -eq ($ShapeShift[1] -band $Grid[$r + 1]) -and
        $Grid[$r + 2] -eq ($ShapeShift[2] -band $Grid[$r + 2])
    ) { return $true } else { return $false }
}

# Given a grid and sprite (shape & coordinates), XOR the shape and grid's bits
function Place-Shape {
    [CmdletBinding()]param([long[]]$Grid, [int]$cols, [int]$Shape9Bits, [int]$r, [int]$c)
    $DebugReq = ($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters['Debug'])
    $ShapeShift = @(
        ([long]$Shape9Bits -band 0b111) -shl $c  # top row moved right $c bits
        ([long]$Shape9Bits -band 0b111000) -shr 3 -shl $c  # middle row
        ([long]$Shape9Bits -band 0b111000000) -shr 6 -shl $c  # bottom row
    )
    $GridCopy = [long[]]::new($Grid.Count)
    [System.Array]::Copy($Grid, $GridCopy, $Grid.Count)
    $GridCopy[$r  ] = ($ShapeShift[0] -bxor $Grid[$r  ])
    $GridCopy[$r + 1] = ($ShapeShift[1] -bxor $Grid[$r + 1])
    $GridCopy[$r + 2] = ($ShapeShift[2] -bxor $Grid[$r + 2])
    if ($DebugReq) {
        Write-Debug ("`n" + (Format-Grid $GridCopy $cols))
    }
    Write-Output -NoEnumerate $GridCopy
}

# for a brute-force worst-case packing,
#   find the coordinates of the next bit that's still turned on
function Find-NextEmptyCorner {
    [CmdletBinding()]param(
        [long[]]$Grid,
        [int]$cols,
        [int]$r,
        [int]$c
    )
    do {
        $r++;
        if ($r -gt ($Grid.Count - 3)) {
            $r = 0; $c++
            if ($c -gt ($cols - 3)) {
                Write-Output -NoEnumerate @(-1, -1)
                return
            }
        }
        $CheckBit = $Grid[$r] -band (1 -shl $c)
    } while ($CheckBit -eq 0)
    Write-Output $r, $c
}

# for a brute-force packing, find the next shape orientation to try
function Find-NextShapeOrientation {
    [CmdletBinding()]param(
        $ParsedShapes,
        [int[]]$WorkOrder,
        [int]$ShapeIndex,
        [int]$OrientationIndex
    )
    do {
        $OrientationIndex++
        if ($ParsedShapes[$ShapeIndex].Count -lt $OrientationIndex) {
            $OrientationIndex = 0; $ShapeIndex++
            if ($ShapeIndex -ge $WorkOrder.Count) {
                Write-Output -NoEnumerate @(-1, -1)
                return
            }
        }
    } until ($WorkOrder[$ShapeIndex] -gt 0)

    Write-Output $ShapeIndex, $OrientationIndex
}

# for a brute-force packing, recursively continue to try packing shapes
#   (doesnt' work yet)
function Pack-NextShape {
    # braindead, not comprehensive yet...
    [CmdletBinding()]param(
        $ParsedShapes,
        [int[]]$WorkOrderState,
        [long[]]$GridState, [int]$Cols,
        [int]$rPrev, [int]$cPrev
    )
    # start on remaining shapes in the work order
    $ShapeId, $Orientation = Find-NextShapeOrientation $ParsedShapes $WorkOrderState 0 -1
    if ($ShapeId -eq -1) { return $true }  # success
    $Shape9Bits = $ParsedShapes[$ShapeId][$Orientation]
    do {
        $r, $c = Find-NextEmptyCorner $GridState $cols $rPrev $cPrev  # start on remaining space
        if ($r -eq -1) {
            $r, $c = $rPrev, $cPrev  # if exhausted, try again with some other shape orientation
            $ShapeId, $Orientation = Find-NextShapeOrientation $ShapeId, $Orientation
            if ($ShapeId -eq -1) { return $false }  # no more space or shapes
        }
        $doesnotfit = Test-3x3Collision -Debug $GridState $Cols $Shape9Bits $r $c
    } while ($doesnotfit)  # keep looking until no collision

    $c = $GridState.Count
    $NewGState = [long[]]::new($c); [System.Array]::Copy($GridState, $NewGState, $c)
    $c = $WorkOrderState.Count
    $NewWorking = [long[]]::new($c); [System.Array]::Copy($WorkOrderState, $NewWorking, $c)
    $NewWorking[$ShapeId]--  # no collision means this shape can be successfully placed
    Place-Shape $NewGState, $cols, $Shape9Bits, $r, $c
    # keep going recursively until all shapes placed (success) or no more space to place a shape (failure)
    $success = Pack-NextShape $NewGState, $cols, $Shape9Bits, $r, $c
    return $success
}

# Forget wasting more time trying to implement a brute-force that's going to take too much time anyway...

# $script:ShapeCatalog = Parse-3x3Shapes $inp $ShapeCount
$global:ShapeCatalog = Parse-3x3Shapes $inp $ShapeCount
$global:PackProblems = Parse-Packings $inp $EnvelopeCount $ShapeCatalog
# Try one problem's envelope and its associated shape collection (Working WorkOrder passed by values)
#   Let's go with the last problem in the list, why not?...
$Problem = $PackProblems[436]
$Enclosure = Get-Grid $Problem.Envelope
$EnclosureWidth = $Problem.Envelope[0]
$Working = [int[]]::new($ShapeCount); [System.Array]::Copy($Problem.WorkOrder, $Working, $ShapeCount)

# Place first shape
#$FirstShapeId, $FirstOrient = Find-NextShapeOrientation $ShapeCatalog $Working 0 -1
#$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[$FirstShapeId][$FirstOrient] 0 0
# #$Encl1 = Place-Shape -Debug $Enclosure $Problem.Envelope[0] $Working $ShapeCatalog[4][0] $r $c
#$Working[$FirstShapeId]--
# $Encl2 = Place-Shape -Debug $Encl1 4 $ShapeCatalog[4][3] 1 1
# $Working[4]--

# Pack the rest
# if (Pack-NextShape $global:ShapeCatalog $Working $Encl1 $EnclosureWidth 0 0) {
#     "Success"
# }  # too much work to figure out...

# Instead, let's try manually packing some shapes.
# Here are a few somewhat efficient ways to pack subsets of shapes:
<#
    0:  1:  2:  3:  4:  5: 
    ##. #.# #.# #.# ### ..#    tighter packs key: (shape IDs)
    .## ### ### #.# .## ###                       (cols x rows)
    ..# #.# .## ### ..# ###                       (leftovers)

    ***# 4,4  | ###+ 4,0  | .##+ 0,0  | ##*** 2,5  | ##*** 5,5
    **## 4x3  | ##++ 4x3  | ##++ 4x3  | ##**. 5x3  | ##.** 5x3
    *### (0)  | #++. (1)  | #++. (2)  | ###** (1)  | ###** (1)

    ###.      | .***
    #*#* 3,3  | ##** 5,5
    #*#* 4x4  | ##** 4x4
    .*** (2)  | ###. (2)

    ###..      | ###.. .##..      | ###.. ###..
    .#*** 1,1  | ##**. ##*** 2,2  | .#**. .#*** 1,2
    ###*. 5x4  | .##** ###** 5x4  | ###** ###** 5x4
    ..*** (6)  | ..***,..**. (6)  | ..***,..**. (6)

    ###+++.          | .##+++.          |
    ##**++# 4,4,2,2  | ##**++# 0,0,2,2  |
    #**++## 7x4      | #**++## 7x4      |
    .***### (2)      | .***##. (4)      |
#>

# Show the initial work order:
$Working -join ','; "`n"

# start with two columns of shape index 4 - those consume all 12 bits in a 4x3 subrectangle
3, 9 | Foreach-Object {
    $tc = $_ # pack 4r x 3c 4,4
    10..0 | Foreach-Object {
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[4][1] ($_ * 4) $tc
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[4][1] ($_ * 4) $tc
        $Working[4]--; $Working -join ','; $Enclosure = $Encl1
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[4][2] (1 + $_ * 4) $tc
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[4][2] (1 + $_ * 4) $tc
        $Working[4]--; $Working -join ','; $Enclosure = $Encl1;
    }
}

# Then two more columns of shape index 0 - those consume 10 of 12 bits in a 4x3 subrectangle
0, 6 | Foreach-Object {
    $tc = $_  # pack 4r x 3c 0,0
    10..0 | Foreach-Object {
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[0][0] ($_ * 4) $tc
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[0][0] ($_ * 4) $tc
        $Working[0]--; $Working -join ','; $Enclosure = $Encl1
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[0][1] (1 + $_ * 4) $tc
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[0][1] (1 + $_ * 4) $tc
        $Working[0]--; $Working -join ','; $Enclosure = $Encl1;
    }
}

# then a column of shape index 3 - those consume 14 of 16 bits in a 4x4 subrectangle
24 | Foreach-Object {
    $tc = $_  # pack 4r x 4c, 3,3
    10..0 | Foreach-Object {
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[3][2] ($_ * 4) ($tc + 1)
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[3][2] ($_ * 4) ($tc + 1)
        $Working[3]--; $Working -join ','; $Enclosure = $Encl1
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[3][1] (1 + $_ * 4) $tc
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[3][1] (1 + $_ * 4) $tc
        $Working[3]--; $Working -join ','; $Enclosure = $Encl1;
    }
}

# then four columns of shape indexes 2 & 5 - those consume 14 of 15 bits in a 5x3 rectangle
12, 15, 18, 21  | Foreach-Object {
    $tc = $_  # pack 5r x 3c, 2,5
    8..0 | Foreach-Object {
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[2][1] ($_ * 5) $tc
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[2][1] ($_ * 5) $tc
        $Working[2]--; $Working -join ','; $Enclosure = $Encl1
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[5][7] (2 + $_ * 5) $tc
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[5][7] (2 + $_ * 5) $tc
        $Working[5]--; $Working -join ','; $Enclosure = $Encl1;
    }
}

# then a column of index 1 - those consume 10 of 16 bits in a 5x4 rectangle
28 | Foreach-Object {
    $tc = $_  # stagger-pack 5r x 4c > 4r x 4c 1,1
    10..0 | Foreach-Object {
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[1][0] ($_ * 4) ($tc + 1)
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[1][0] ($_ * 4) ($tc + 1)
        $Working[1]--; $Working -join ','; $Enclosure = $Encl1
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[1][0] (2 + $_ * 4) $tc
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[1][0] (2 + $_ * 4) $tc
        $Working[1]--; $Working -join ','; $Enclosure = $Encl1;
    }
}

# then a partial column of indexes 0 2 - those consume 24 of 28 bits in a 7x4 rectangle
32 | Foreach-Object {
    $tc = $_  # pack 7r x 4c, 0 0 2 2
    1..0 | Foreach-Object {
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[0][3] (4 + $_ * 7) $tc
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[0][3] (4 + $_ * 7) $tc
        $Working[0]--; $Working -join ','; $Enclosure = $Encl1
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[2][5] (3 + $_ * 7) ($tc + 1)
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[2][5] (3 + $_ * 7) ($tc+1)
        $Working[2]--; $Working -join ','; $Enclosure = $Encl1;
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[2][2] (1 + $_ * 7) $tc
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[2][2] (1 + $_ * 7) $tc
        $Working[2]--; $Working -join ','; $Enclosure = $Encl1;
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[0][2] ($_ * 7) ($tc + 1)
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[0][2] ($_ * 7) ($tc+1)
        $Working[0]--; $Working -join ','; $Enclosure = $Encl1
    }
}

# in the same column, pairs of index 3
32 | Foreach-Object {
    $tc = $_  # pack 4r x 4c, 3,3
    9..3 | Foreach-Object {
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[3][2] (2 + $_ * 4) ($tc + 1)
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[3][2] (2 + $_ * 4) ($tc + 1)
        $Working[3]--; $Working -join ','; $Enclosure = $Encl1
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[3][1] (3 + $_ * 4) $tc
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[3][1] (3 + $_ * 4) $tc
        $Working[3]--; $Working -join ','; $Enclosure = $Encl1;
    }
}

# in next column, index 5 pairs - like index 3s, those also use 14 of 16 bits in a 4x4 subrectangle
36 | Foreach-Object {
    $tc = $_  # pack 4r x 4c, 5,5
    0..2 | Foreach-Object {
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[5][3] ($_ * 4) ($tc + 1)
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[5][3] ($_ * 4) ($tc + 1)
        $Working[5]--; $Working -join ','; $Enclosure = $Encl1
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[5][4] (1 + $_ * 4) $tc
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[5][4] (1 + $_ * 4) $tc
        $Working[5]--; $Working -join ','; $Enclosure = $Encl1;
    }
}

# same column, more index 1 pairs
36 | Foreach-Object {
    $tc = $_  # pack 4r x 4c, 1,1
    3..5 | Foreach-Object {
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[1][0] ($_ * 4) ($tc + 1)
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[1][0] ($_ * 4) ($tc + 1)
        $Working[1]--; $Working -join ','; $Enclosure = $Encl1
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[1][0] (2 + $_ * 4) $tc
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[1][0] (2 + $_ * 4) $tc
        $Working[1]--; $Working -join ','; $Enclosure = $Encl1;
    }
}

# finally, the last pair of 4s somewhere else (enclosure's right edge)
45 | Foreach-Object {
    $tc = $_  # pack 3r x 4c, 4,4
    41 | Foreach-Object {
        $Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[4][1] ($_ - 2) $tc
        #$Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[4][1] ($_) $tc
        $Working[4]--; $Working -join ','; $Enclosure = $Encl1
        #$Encl1 = Place-Shape        $Enclosure $EnclosureWidth $ShapeCatalog[4][2] (1 + $_) $tc
        $Encl1 = Place-Shape -Debug $Enclosure $EnclosureWidth $ShapeCatalog[4][2] (1 + $_) $tc
        $Working[4]--; $Working -join ','; $Enclosure = $Encl1
        #Yay, all shapes are finally placed now!
    }
}

# That was fun. Now let's study the problems again and find an easier way to figure these out:
function Measure-AllProblems {
    param($PackProblems)
    for ($i = 0; $i -lt $PackProblems.Count; $i++) {
        $Problem = $PackProblems[$i]
        $EnclosureArea = $Problem.Envelope[0] * $Problem.Envelope[1]
        $AggregateWOCount = ($Problem.WorkOrder | Measure-Object -Sum).Sum
        # In a nontrivial packing, every shape gets its own unshared 3x3 space
        if ($EnclosureArea -lt $AggregateWOCount * 9) {
            Write-Output "$EnclosureArea <-- $($AggregateWOCount * 9)  [Pack harder!]"
        }
        else {
            Write-Output "$EnclosureArea <-- $($AggregateWOCount * 9)"
        }
    }
}
# how many of them actually need tighter nontrivial packings?
(Measure-AllProblems $PackProblems | Select-String "Pack harder" | Measure-Object -Sum).Sum
# How many total?
$PackProblems.Count
