class Point {
    [long]$X
    [long]$Y
    Point() {}
    Point([long]$Xp, [long]$Yp) { $this.X = $Xp; $this.Y = $Yp }
    Point([string]$s) {
        $sX,$sY = $s.Split(",")
        $this.X = [long]$sX
        $this.Y = [long]$sY
    }
    [string] ToString() { return "{0},{1}" -f $this.X,$this.Y }
}

# example by Jennifer Ripple from O'Rourke, Computational Geometry in C, 1994, pp 94-96

$inp = @(
 "3,-2", "5,1", "7,4", "6,5", "4,2", "3,3", "3,5", "2,5", "0,5", "0,1",
 "-3,4", "-2,2", "0,0", "-3,2", "-5,2", "-5,1", "-5,-1", "1,-2", "-3,-2"
)

[Point[]]$Coords = @()
foreach ($row in $inp) { $Coords += ,([Point]::new($row)) }
[Point[]]$transformedCoords = @()
foreach ($P in $Coords) { $transformedCoords += ,([Point]::new($P.X+6,$P.Y+3)) }

foreach ($P in $transformedCoords) { Write-Output $P.ToString() }
