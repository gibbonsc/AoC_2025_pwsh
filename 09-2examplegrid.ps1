$inp = Get-Content 09-example.txt
$Xcoords=@()
$Ycoords=@()
$Xmax=$Ymax=0
foreach ($row in $inp) {
    $coord = $row.Split(",")
    $Xc = +$coord[0]
    $Yc = +$coord[1]
    $Xcoords += ,$Xc
    $Ycoords += ,$Yc
    if (+$Xc -gt $Xmax) { $Xmax = $Xc }
    if (+$Yc -gt $Ymax) { $Ymax = $Yc }
#    ($Xcoords -join " ") + " +$Xmax"
#    ($YCoords -join " ") + " +$Ymax"
}
#"$($Xcoords.Count) in 0,0 - $Xmax,$Ymax"
foreach ($row in 0..($Ymax+1)) {
    $s = ""
    foreach ($col in 0..($Xmax+1)) {
        $mark = "."
        for ($i=0; $i -lt $Xcoords.Count; $i++) {
            if ($Xcoords[$i] -eq $col -and $Ycoords[$i] -eq $row) {
                $mark = "#"
                break
            }
        }
        $s += $mark
    }
    $s
}
