<# https://adventofcode.com/2025/day/8
  Part 1
  Connect the closest 1000 boxes
    atop posts of varying heights (3D coordinates),
    then identify three largest co-connected clusters
    and multiply their sizes.
  Author: C Gibbons
#>

#$inp = Get-Content ./08-example.txt
$inp = Get-Content ./08-input.txt
#$maxConnections = 10
$maxConnections = 1000

$rows = $inp.Count

class Point {
    [ulong]$X
    [ulong]$Y
    [ulong]$Z
    Point() {}
    Point([ulong]$Xp, [ulong]$Yp, [ulong]$Zp) { $this.X, $this.Y, $this.Z = $Xp, $Yp, $Zp }
    [string] ToString() { return "$this.X,$this.Y,$this.Z" }
}

function DistanceSurrogate {
    param(
        [Parameter(Mandatory = $true)]
        [Point]$P1,
        [Parameter(Mandatory = $true)]
        [Point]$P2
    )
    $diffX = $P1.X - $P2.X
    $diffY = $P1.Y - $P2.Y
    $diffZ = $P1.Z - $P2.Z
    return $diffX * $diffX + $diffY * $diffY + $diffZ * $diffZ
    # actual distance returns square root of result,
    # but squared surrogate is faster, and is still
    # monotonically comparable when used for distance comparisons
}

Write-Host "parsing junction box coordinates..."
[Point[]]$jBoxes = @()
foreach ($line in $inp) {
    $i, $j, $k = $line.Split(",")
    $jBoxes += [Point]::new($i, $j, $k)
}

Write-Host "calculating distances between boxes..."
$FakeDistances = @{}
for ($k = 1; $k -lt $jBoxes.Count; ++$k) {
    for ($j = 0; $j -lt $k; ++$j) {
        $doublet = "$j, $k"
        $fakeDistance = DistanceSurrogate $jBoxes[$j] $jBoxes[$k]
        #Write-Output "$doublet`t$($jBoxes[$j].ToString()) $($jBoxes[$k].ToString())"
        $FakeDistances[$doublet] = $fakeDistance
    }
}
Write-Host "sorting box pairs by distance..."
$sortedPairs = $FakeDistances.GetEnumerator() | Sort-Object Value
$elvesWorked = $SortedPairs[0..($maxConnections - 1)].Name

[bool[]]$connected = 1..$rows | Foreach-Object { $false } # indexes 

[int[][]]$circuits = @()  # to hold collections of indexes of $jBoxes
[string[]]$AlreadyConnected = @()  # to hold pairs of indexes of $jBoxes

Write-Host "discovering circuits..."
foreach ($pair in $elvesWorked) {
    $AlreadyConnected += , $pair
    $j, $k = [int[]]$pair.Split(',')
    if ($connected[$j]) {
        # merge $k into a circuit...
        if ($connected[$k]) {
            # possibly merge two existing circuits?
            $merge = @()
            for ($u = 0; $u -lt $circuits.Count; ++$u) {
                if ($circuits[$u] -contains $j -or $circuits[$u] -contains $k) {
                    foreach ($v in $circuits[$u]) {
                        $merge += , $v
                    }
                }
            }
            $circuits = @( $circuits |
                Where-Object { $_ -notcontains $j -and $_ -notcontains $k } |
                Foreach-Object { ,$_ }
            )
            $circuits += , $merge
        }
        else {
            # merge $k into $j's existing circuit
            $connected[$k] = $true
            for ($u = 0; $u -lt $circuits.Count; ++$u) {
                if ($circuits[$u] -contains $j) {
                    $circuits[$u] += , $k
                    break
                }
            }
        }
    }
    elseif ($connected[$k]) {
        # merge $j into existing circuit
        $connected[$j] = $true
        for ($u = 0; $u -lt $circuits.Count; ++$u) {
            if ($circuits[$u] -contains $k) {
                $circuits[$u] += , $j
                break
            }
        }
    }
    else {
        # new 2-box circuit
        $connected[$j] = $connected[$k] = $true
        $circuits += , @($j, $k)
    }
}

Write-Host "Circuit sizes:"
$sizes = @()
for ($u = 0; $u -lt $circuits.Count; ++$u) {
    #Write-Output $circuits[$u].Count
    $sizes += , $circuits[$u].Count
}
$sizes

$SortedSizes = $sizes | sort
""
$SortedSizes[-1],$SortedSizes[-2],$SortedSizes[-3]
"Product: $($SortedSizes[-1]*$SortedSizes[-2]*$SortedSizes[-3])"
# probably should cache to speed up nested triple loop recalculations, but lazy coder am I...
# for ($i = 0; $i -lt $maxConnections; ++$i) {
#     # find closest pair not already connected
#     $closest = [ulong]100000 * 100000 * 100000 # surrogate for corner-to-corner longest distance
#     $closej, $closek = -1, -1
#     for ($j = 0; $j -lt $jBoxes.Count - 1; ++$j) {
#         for ($k = $j + 1; $k -lt $jBoxes.Count; ++$k) {
#             if ($AlreadyConnected -contains "$j, $k") { continue }
#             $fakeDistance = DistanceSurrogate $jBoxes[$j] $jBoxes[$k]
#             if ($fakeDistance -lt $closest ) {
#                 $closest = $fakeDistance;
#                 $closej = $j
#                 $closek = $k
#             }
#         }
#     }

#     # process new closest pair
#     $AlreadyConnected += , "$closej, $closek"
#     if ($connected[$closej]) {
#         # merge $closek into something...
#         if ($connected[$closek]) {
#             # merge two existing circuits
#             $merge = @()
#             for ($u = 0; $u -lt $circuits.Count; ++$u) {
#                 if ($circuits[$u] -contains $closej -or $circuits[$u] -contains $closek) {
#                     foreach ($v in $circuits[$u]) {
#                         $merge += , $v
#                     }
#                 }
#             }
#             $circuits = @( $circuits |
#                 Where-Object { $_ -notcontains $closej -and $_ -notcontains $closek } |
#                 Foreach-Object { ,$_ }
#             )
#             $circuits += , $merge
#         }
#         else {
#             # merge $closek into $closej's existing circuit
#             $connected[$closek] = $true
#             for ($u = 0; $u -lt $circuits.Count; ++$u) {
#                 if ($circuits[$u] -contains $closej) {
#                     $circuits[$u] += , $closek
#                     break
#                 }
#             }
#         }
#     }
#     elseif ($connected[$closek]) {
#         # merge $closej into existing circuit
#         $connected[$closej] = $true
#         for ($u = 0; $u -lt $circuits.Count; ++$u) {
#             if ($circuits[$u] -contains $closek) {
#                 $circuits[$u] += , $closej
#                 break
#             }
#         }
#     }
#     else {
#         # new 2-box circuit
#         $connected[$closej] = $connected[$closek] = $true
#         $circuits += , @($closej, $closek)
#     }
# }

# for ($u = 0; $u -lt $circuits.Count; ++$u) {
#     Write-Output $circuits[$u].Count
# }