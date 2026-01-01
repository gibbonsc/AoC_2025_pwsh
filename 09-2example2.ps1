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

$inp = @(
  "10,1", "10,3", "7,3", "7,5", "12,5", "12,7", "15,7", "15,13",
  "3,13", "3,11", "5,11", "5,9", "1,9", "1,1"
)

[Point[]]$Coords = @()
foreach ($row in $inp) { $Coords += ,([Point]::new($row)) }
[Point[]]$transformedCoords = @()
foreach ($P in $Coords) { $transformedCoords += ,([Point]::new($P.X,$P.Y)) }

foreach ($P in $transformedCoords) { Write-Output $P.ToString() }
