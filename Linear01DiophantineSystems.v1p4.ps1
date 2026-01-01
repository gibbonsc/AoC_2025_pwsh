# Linear01DiophantineSystems.v1p4.ps1
# Unified toolkit with:
#  - Exact Fraction class
#  - RREF (Gauss–Jordan)
#  - Parameterization
#  - Global bounds tightening (existential selection)
#  - Enumeration with optional global-only bounds and softened local bounds
# Author: Carl Gibbons & M365 Copilot
# Date: 2025-12-24

using namespace System.Numerics

class Fraction {
    [BigInteger]$Num; [BigInteger]$Den
    Fraction([BigInteger]$n,[BigInteger]$d){ if($d -eq 0){ throw [System.DivideByZeroException]::new("Denominator cannot be zero.") } if($d -lt 0){ $n=-$n; $d=-$d } $this.Num=$n; $this.Den=$d; $this.Simplify() }
    static [Fraction] FromInt([BigInteger]$n){ return [Fraction]::new($n,[BigInteger]1) }
    [void]Simplify(){ $an=[BigInteger]::Abs($this.Num); $g=[BigInteger]::GreatestCommonDivisor($an,$this.Den); if($g -ne 0){ $this.Num=[BigInteger]::op_Division($this.Num,$g); $this.Den=[BigInteger]::op_Division($this.Den,$g) } }
    static [Fraction] Add([Fraction]$a,[Fraction]$b){ return [Fraction]::new($a.Num*$b.Den + $b.Num*$a.Den, $a.Den*$b.Den) }
    static [Fraction] Sub([Fraction]$a,[Fraction]$b){ return [Fraction]::new($a.Num*$b.Den - $b.Num*$a.Den, $a.Den*$b.Den) }
    static [Fraction] Mul([Fraction]$a,[Fraction]$b){ return [Fraction]::new($a.Num*$b.Num, $a.Den*$b.Den) }
    static [Fraction] Div([Fraction]$a,[Fraction]$b){ if($b.Num -eq 0){ throw [System.DivideByZeroException]::new("Division by zero fraction.") } return [Fraction]::new($a.Num*$b.Den, $a.Den*$b.Num) }
    [bool] IsZero(){ return $this.Num -eq 0 }
    [string] ToString(){ if($this.Den -eq 1){ return $this.Num.ToString() } else { return "$($this.Num)/$($this.Den)" } }
}

function ConvertTo-Fraction { param([Parameter(Mandatory=$true)][object]$Value)
  switch($Value.GetType().FullName){
    'System.Numerics.BigInteger' { return [Fraction]::FromInt([BigInteger]$Value) }
    'System.Int32' { return [Fraction]::FromInt([BigInteger][int]$Value) }
    'System.Int64' { return [Fraction]::FromInt([BigInteger][long]$Value) }
    'System.String' { $s=[string]$Value; if($s -match '^\s*([+-]?\d+)\s*/\s*([+-]?\d+)\s*$'){ $n=[BigInteger]::Parse($Matches[1]); $d=[BigInteger]::Parse($Matches[2]); return [Fraction]::new($n,$d) } elseif($s -match '^\s*([+-]?\d+)\s*$'){ $n=[BigInteger]::Parse($Matches[1]); return [Fraction]::FromInt($n) } else { throw "Unsupported string format: '$s'" } }
    default { throw "Unsupported entry type: $($Value.GetType().FullName)" }
  }
}

function Get-FloorFraction { param([Fraction]$f) $q=[BigInteger]::op_Division($f.Num,$f.Den); if($f.Num -lt 0 -and ($f.Num % $f.Den) -ne 0){ return $q - 1 } else { return $q } }
function Get-CeilingFraction { param([Fraction]$f) $q=[BigInteger]::op_Division($f.Num,$f.Den); if($f.Num -gt 0 -and ($f.Num % $f.Den) -ne 0){ return $q + 1 } elseif($f.Num -lt 0 -and ($f.Num % $f.Den) -ne 0){ return $q } else { return $q } }

function Reduce-MatrixRREF { [CmdletBinding()] param([Parameter(Mandatory=$true)][object[]]$Matrix,[switch]$ReturnAsStrings)
  if(-not $Matrix -or -not ($Matrix[0] -is [System.Collections.IEnumerable])){ throw "Matrix must be an array of rows (each row an array)." }
  $rows=@(); $colCount=$null
  foreach($row in $Matrix){ $frRow=@(); foreach($x in $row){ $frRow += ,(ConvertTo-Fraction -Value $x) } if($null -eq $colCount){ $colCount=$frRow.Count } elseif($frRow.Count -ne $colCount){ throw "All rows must have the same number of columns." } $rows += ,$frRow }
  $rowCount=$rows.Count; $lead=0
  for($r=0; $r -lt $rowCount; $r++){
    if($lead -ge $colCount){ break }
    $i=$r; while($i -lt $rowCount -and $rows[$i][$lead].IsZero()){ $i++ }
    if($i -eq $rowCount){ $lead++; $r--; continue }
    if($i -ne $r){ $tmp=$rows[$r]; $rows[$r]=$rows[$i]; $rows[$i]=$tmp }
    $pivot=$rows[$r][$lead]
    for($j=0; $j -lt $colCount; $j++){ $rows[$r][$j] = [Fraction]::Div($rows[$r][$j], $pivot) }
    for($i2=0; $i2 -lt $rowCount; $i2++){
      if($i2 -eq $r){ continue }
      $factor=$rows[$i2][$lead]
      if(-not $factor.IsZero()){
        for($j=0; $j -lt $colCount; $j++){ $rows[$i2][$j] = [Fraction]::Sub($rows[$i2][$j], [Fraction]::Mul($factor, $rows[$r][$j])) }
      }
    }
    $lead++
  }
  if($ReturnAsStrings){ return $rows | ForEach-Object { $_ | ForEach-Object { $_.ToString() } } } else { return $rows }
}

function Format-Matrix { [CmdletBinding()] param([Parameter(Mandatory=$true)][object[]]$Matrix)
  $lines=@(); foreach($row in $Matrix){ $cells=@(); foreach($x in $row){ if($x -is [Fraction]){ $cells += ,($x.ToString()) } else { $cells += ,([string]$x) } } $lines += ,("[ " + ($cells -join "`t") + " ]") } $lines -join [Environment]::NewLine }

function Get-RhsUpperBounds { [CmdletBinding()] param([Parameter(Mandatory=$true)][object[]]$Matrix,[string[]]$VariableNames)
  $varCount=$VariableNames.Count; $ub=@{}; for($i=0; $i -lt $varCount; $i++){ $ub[$VariableNames[$i]]=$null }
  foreach($row in $Matrix){ $rhs=[BigInteger][int]$row[$varCount]; for($j=0; $j -lt $varCount; $j++){ $coef=[int]$row[$j]; if($coef -ne 0){ if($ub[$VariableNames[$j]] -eq $null -or $rhs -lt $ub[$VariableNames[$j]]){ $ub[$VariableNames[$j]]=$rhs } } } }
  return $ub
}

function Get-DiophantineParameterization { [CmdletBinding()] param([Parameter(Mandatory=$true)][object[]]$Matrix,[string[]]$VariableNames,[switch]$NonnegativeVars,[hashtable]$FreeVarBounds,[switch]$Trace)
  if(-not $VariableNames){ $varCount=($Matrix[0].Count) - 1; $VariableNames=(0..($varCount-1)) | ForEach-Object { "p$_" } }
  $varCount=$VariableNames.Count; $rhsIndex=$varCount
  $R=Reduce-MatrixRREF -Matrix $Matrix
  for($ri=0; $ri -lt $R.Count; $ri++){
    $row=$R[$ri]
    $allZero=$true; for($c=0; $c -lt $varCount; $c++){ if($row[$c].Num -ne 0){ $allZero=$false; break } }
    if($allZero -and $row[$rhsIndex].Num -ne 0){ throw "System is inconsistent: 0 = nonzero at row $ri." }
  }
  $pivotCols=@(); for($c=0; $c -lt $varCount; $c++){ $ones=0; $zerosElse=$true; $pivotRow=-1; for($ri=0; $ri -lt $R.Count; $ri++){ $v=$R[$ri][$c]; if($v.Den -eq 1 -and $v.Num -eq 1){ $ones++; $pivotRow=$ri } elseif($v.Num -ne 0){ $zerosElse=$false } } if($ones -eq 1 -and $zerosElse){ $pivotCols += [pscustomobject]@{ Col=$c; Row=$pivotRow } } }
  $pivotIndices=$pivotCols | ForEach-Object { $_.Col }; $freeCols=(0..($varCount-1)) | Where-Object { $pivotIndices -notcontains $_ }
  $expressions=@(); foreach($p in $pivotCols){ $row=$R[$p.Row]; $pivotName=$VariableNames[$p.Col]; $rhs=$row[$rhsIndex]; $terms=@(); foreach($fc in $freeCols){ $coef=$row[$fc]; if($coef.Num -ne 0){ $terms += [pscustomobject]@{ Name=$VariableNames[$fc]; Coef=$coef } } } $expressions += [pscustomobject]@{ Variable=$pivotName; RHS=$rhs; Terms=$terms } }
  $freeNamesUnordered=@($freeCols | ForEach-Object { $VariableNames[$_] })
  $ordering=@(); foreach($fn in $freeNamesUnordered){ $neg=0; $pos=0; foreach($expr in $expressions){ foreach($t in $expr.Terms){ if($t.Name -eq $fn){ if($t.Coef.Num -lt 0){ $neg++ } elseif($t.Coef.Num -gt 0){ $pos++ } } } } $ordering += [pscustomobject]@{ Name=$fn; Neg=$neg; Pos=$pos } }
  $freeNames=@(($ordering | Sort-Object -Property @{Expression={$_.Neg};Descending=$true}, @{Expression={$_.Pos};Descending=$false}, Name) | ForEach-Object { $_.Name })
  $bounds=@{}; foreach($fn in $freeNames){ $bounds[$fn]=@{ Min=[BigInteger]0; Max=[bigint]::Parse("9223372036854775807") } }
  if($FreeVarBounds){ foreach($key in $FreeVarBounds.Keys){ if($bounds.ContainsKey($key)){ if($FreeVarBounds[$key].ContainsKey('Min')){ $bounds[$key]['Min']=[BigInteger]$FreeVarBounds[$key]['Min'] }; if($FreeVarBounds[$key].ContainsKey('Max')){ $bounds[$key]['Max']=[BigInteger]$FreeVarBounds[$key]['Max'] } } } }
  if($NonnegativeVars){ foreach($fn in $freeNames){ if($bounds[$fn]['Min'] -lt 0){ $bounds[$fn]['Min']=[BigInteger]0 } } }
  $rhsUB=Get-RhsUpperBounds -Matrix $Matrix -VariableNames $VariableNames
  foreach($fn in $freeNames){ if($rhsUB[$fn] -ne $null){ $gMax=$bounds[$fn]['Max']; if($gMax -eq [bigint]::Parse("9223372036854775807") -or $rhsUB[$fn] -lt $gMax){ $bounds[$fn]['Max']=[BigInteger]$rhsUB[$fn] } } }
  $obj=[pscustomobject]@{ VariableNames=$VariableNames; FreeVariables=$freeNames; PivotVariables=($pivotCols|ForEach-Object{ $VariableNames[$_.Col] }); Expressions=$expressions; Bounds=$bounds; Rref=$R; RHSIndex=$rhsIndex }
  if($Trace){ Write-Host "Free order:  " ($freeNames -join ', ') -ForegroundColor Cyan }
  return $obj
}

function Tighten-GlobalBounds { [CmdletBinding()] param([Parameter(Mandatory=$true)] $ParamObj,[switch]$NonnegativeVars,[int]$MaxIters=50,[switch]$Trace)
  $free=@($ParamObj.FreeVariables); $bounds=$ParamObj.Bounds
  for($iter=0; $iter -lt $MaxIters; $iter++){
    $changed=$false
    foreach($name in $free){
      $minCur=$bounds[$name]['Min']; $maxCur=$bounds[$name]['Max']
      $minNew=$minCur; $maxNew=$maxCur
      foreach($expr in $ParamObj.Expressions){
        $b=$expr.RHS; $coefK=$null; foreach($t in $expr.Terms){ if($t.Name -eq $name){ $coefK=$t.Coef; break } } ; if($null -eq $coefK){ continue }
        $sumMin=[Fraction]::FromInt([BigInteger]0); $sumMax=[Fraction]::FromInt([BigInteger]0)
        foreach($t in $expr.Terms){ if($t.Name -eq $name){ continue } $a=$t.Coef; $bn=$bounds[$t.Name]; if($null -eq $bn){ continue } $minT=[Fraction]::FromInt([BigInteger]$bn['Min']); $maxT=[Fraction]::FromInt([BigInteger]$bn['Max']); if($a.Num -ge 0){ $sumMin=[Fraction]::Add($sumMin,[Fraction]::Mul($a,$minT)); $sumMax=[Fraction]::Add($sumMax,[Fraction]::Mul($a,$maxT)) } else { $sumMin=[Fraction]::Add($sumMin,[Fraction]::Mul($a,$maxT)); $sumMax=[Fraction]::Add($sumMax,[Fraction]::Mul($a,$minT)) } }
        if($coefK.Num -gt 0){ $rhsForUB=[Fraction]::Sub($b,$sumMin); $ubCand=Get-FloorFraction([Fraction]::Div($rhsForUB,$coefK)); if($ubCand -lt $maxNew){ $maxNew=$ubCand } }
        elseif($coefK.Num -lt 0){ $rhsForLB=[Fraction]::Sub($b,$sumMin); $lbCand=Get-CeilingFraction([Fraction]::Div($rhsForLB,$coefK)); if($lbCand -gt $minNew){ $minNew=$lbCand } }
      }
      if($NonnegativeVars -and $minNew -lt 0){ $minNew=[BigInteger]0 }
      if($minNew -gt $maxNew){ $bounds[$name]['Min']=$minNew; $bounds[$name]['Max']=$minNew; $changed=$true; if($Trace){ Write-Host "[$name] min>max -> clamped to $minNew" -ForegroundColor Yellow } ; continue }
      if($minNew -gt $bounds[$name]['Min']){ $bounds[$name]['Min']=$minNew; $changed=$true; if($Trace){ Write-Host "[$name] Min tightened -> $minNew" -ForegroundColor Green } }
      if($maxNew -lt $bounds[$name]['Max']){ $bounds[$name]['Max']=$maxNew; $changed=$true; if($Trace){ Write-Host "[$name] Max tightened -> $maxNew" -ForegroundColor Green } }
    }
    if(-not $changed){ break }
  }
  return $ParamObj
}

function Evaluate-ParamSolution { [CmdletBinding()] param([Parameter(Mandatory=$true)] $ParamObj,[hashtable]$FreeAssignment)
  $values=@{}; $freeArray=@($ParamObj.FreeVariables); foreach($fn in $freeArray){ $values[$fn]=[BigInteger]$FreeAssignment[$fn] }
  foreach($expr in $ParamObj.Expressions){ $sum=$expr.RHS; foreach($t in $expr.Terms){ $tv=[Fraction]::FromInt([BigInteger]$FreeAssignment[$t.Name]); $prod=[Fraction]::Mul($t.Coef,$tv); $sum=[Fraction]::Sub($sum,$prod) } ; if($sum.Den -ne 1){ return $null } ; $values[$expr.Variable]=$sum.Num }
  return $values
}

function Get-LocalBoundsForFreeVar { param([Parameter(Mandatory=$true)] $ParamObj,[hashtable]$Assign,[string]$VarName,[switch]$NonnegativeVars)
  $lb=$null; $ub=$null
  foreach($expr in $ParamObj.Expressions){ $rhsEff=$expr.RHS; foreach($t in $expr.Terms){ if($Assign.ContainsKey($t.Name)){ $tv=[Fraction]::FromInt([BigInteger]$Assign[$t.Name]); $rhsEff=[Fraction]::Sub($rhsEff,[Fraction]::Mul($t.Coef,$tv)) } }
    $coef=$null; foreach($t in $expr.Terms){ if($t.Name -eq $VarName){ $coef=$t.Coef; break } }
    if($null -eq $coef){ continue }
    if($coef.Num -gt 0){ $ubCand=Get-FloorFraction([Fraction]::Div($rhsEff,$coef)); if($null -eq $ub -or $ubCand -lt $ub){ $ub=$ubCand } }
    elseif($coef.Num -lt 0){ $lbCand=Get-CeilingFraction([Fraction]::Div($rhsEff,$coef)); if($null -eq $lb -or $lbCand -gt $lb){ $lb=$lbCand } }
  }
  $gMin=$ParamObj.Bounds[$VarName]['Min']; $gMax=$ParamObj.Bounds[$VarName]['Max']
  if($null -ne $gMin){ if($null -eq $lb -or $gMin -gt $lb){ $lb=$gMin } }
  if($null -ne $gMax -and $gMax -ne [bigint]::Parse("9223372036854775807")){ if($null -eq $ub -or $gMax -lt $ub){ $ub=$gMax } }
  if($NonnegativeVars -and ($null -eq $lb -or $lb -lt 0)){ $lb=[BigInteger]0 }
  return @{ Min=$lb; Max=$ub }
}

function Enumerate-DiophantineSolutions { [CmdletBinding()] param([Parameter(Mandatory=$true)][object[]]$Matrix,[string[]]$VariableNames,[switch]$NonnegativeVars,[hashtable]$FreeVarBounds,[int]$MaxSolutions=[int]::MaxValue,[switch]$ReturnAsObjects,[switch]$Trace,[switch]$UseGlobalBoundsOnly)
  $param=Get-DiophantineParameterization -Matrix $Matrix -VariableNames $VariableNames -NonnegativeVars:$NonnegativeVars -FreeVarBounds $FreeVarBounds -Trace:$Trace
  $param=Tighten-GlobalBounds -ParamObj $param -NonnegativeVars:$NonnegativeVars -Trace:$Trace
  $free=@($param.FreeVariables)
  if($free.Count -eq 0){ $vals=Evaluate-ParamSolution -ParamObj $param -FreeAssignment @{}; if($NonnegativeVars){ foreach($name in $param.VariableNames){ if($vals[$name] -lt 0){ return [pscustomobject]@{ Parameterization=$param; Solutions=@() } } } } $solArray=New-Object System.Collections.ArrayList; if($ReturnAsObjects){ [void]$solArray.Add($vals) } else { $row=@($param.VariableNames | ForEach-Object { $vals[$_] }); [void]$solArray.Add($row) } ; return [pscustomobject]@{ Parameterization=$param; Solutions=$solArray.ToArray() } }
  $solutions=New-Object System.Collections.ArrayList
  function Recurse([int]$idx,[hashtable]$assign){ if($solutions.Count -ge $MaxSolutions){ return } ; if($idx -ge $free.Count){ $vals=Evaluate-ParamSolution -ParamObj $param -FreeAssignment $assign; if($null -ne $vals){ if($NonnegativeVars){ $ok=$true; foreach($name in $param.VariableNames){ if($vals[$name] -lt 0){ $ok=$false; break } } ; if(-not $ok){ return } } ; if($ReturnAsObjects){ [void]$solutions.Add($vals) } else { $row=@($param.VariableNames | ForEach-Object { $vals[$_] }); [void]$solutions.Add($row) } } ; return }
    $name=$free[$idx]
    if($UseGlobalBoundsOnly){ $min=$param.Bounds[$name]['Min']; $max=$param.Bounds[$name]['Max'] } else { $local=Get-LocalBoundsForFreeVar -ParamObj $param -Assign $assign -VarName $name -NonnegativeVars:$NonnegativeVars ; $min=$local['Min']; $max=$local['Max'] }
    if($Trace){ Write-Host (" -> choosing {0} in [{1}..{2}]" -f $name,$min,$max) -ForegroundColor Magenta }
    if($null -eq $max){ throw "Free variable '$name' lacks a finite upper bound. Tightening failed to cap it; supply -FreeVarBounds." } ; if($min -gt $max){ if($Trace){ Write-Host (" -> pruned {0}: min>max [{1}>{2}]" -f $name,$min,$max) -ForegroundColor DarkYellow } ; return }
    for($t=$min; $t -le $max; $t+=1){ $assign[$name]=[BigInteger]$t; Recurse ($idx+1) $assign; if($solutions.Count -ge $MaxSolutions){ break } }
  }
  Recurse 0 (@{})
  [pscustomobject]@{ Parameterization=$param; Solutions=$solutions.ToArray() }
}

function Show-Parameterization { [CmdletBinding()] param([Parameter(Mandatory=$true)] $ParamObj)
  $lines=@(); foreach($expr in $ParamObj.Expressions){ $rhs=$expr.RHS.ToString(); $parts=@(); foreach($t in $expr.Terms){ $parts += "- (" + $t.Coef.ToString() + ")*" + $t.Name } ; $line=$expr.Variable + " = " + $rhs; if($parts.Count -gt 0){ $line += " " + ($parts -join " ") } ; $lines += $line } ; $lines }

function Show-Solutions { [CmdletBinding(DefaultParameterSetName='FromResults')] param([Parameter(ParameterSetName='FromResults',Mandatory=$true,Position=0)] $InputObject,[Parameter(ParameterSetName='FromSolutions',Mandatory=$true,Position=0)][object[]]$Solutions,[string[]]$VariableOrder,[switch]$AsCsv)
  if($PSCmdlet.ParameterSetName -eq 'FromResults'){ $sols=$InputObject.Solutions; if(-not $VariableOrder){ $VariableOrder=$InputObject.Parameterization.VariableNames } } else { $sols=$Solutions; if(-not $VariableOrder -and $sols.Count -gt 0 -and ($sols[0] -is [hashtable])){ $VariableOrder=@($sols[0].Keys) } } ; if(-not $VariableOrder){ throw "VariableOrder is required when Solutions are arrays instead of hashtables." } ; if($AsCsv){ foreach($s in $sols){ if($s -is [hashtable]){ $line=($VariableOrder | ForEach-Object { [string]$s[$_] }) -join ','; Write-Output $line } else { Write-Output ([string]::Join(',', @($s))) } } } else { $sols | ForEach-Object { if($_ -is [hashtable]){ [pscustomobject]$_ } else { [pscustomobject]@{} } } | Select-Object $VariableOrder }
}
