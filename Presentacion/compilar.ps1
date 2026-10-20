$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$taskCompiler = Get-Command xelatex -ErrorAction SilentlyContinue
if ($taskCompiler) { $taskCompilerPath = $taskCompiler.Source }
else {
    $taskCompilerPath = 'C:\Program Files\MiKTeX\miktex\bin\x64\xelatex.exe'
    if (-not (Test-Path -LiteralPath $taskCompilerPath)) { throw 'Instale MiKTeX o TeX Live con xelatex.' }
}
1..2 | ForEach-Object {
    & $taskCompilerPath -interaction=nonstopmode -halt-on-error 'Presentacion_AyCD_EscobarHerrera.tex'
    if ($LASTEXITCODE -ne 0) { throw 'Error de compilación. Consulte el archivo .log.' }
}
