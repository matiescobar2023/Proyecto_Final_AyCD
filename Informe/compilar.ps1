$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$taskCompiler = Get-Command pdflatex -ErrorAction SilentlyContinue
if ($taskCompiler) { $taskCompilerPath = $taskCompiler.Source }
else {
    $taskCompilerPath = 'C:\Program Files\MiKTeX\miktex\bin\x64\pdflatex.exe'
    if (-not (Test-Path -LiteralPath $taskCompilerPath)) { throw 'Instale MiKTeX o TeX Live con pdflatex.' }
}
1..3 | ForEach-Object {
    & $taskCompilerPath -interaction=nonstopmode -halt-on-error 'Informe_AyCD_EscobarHerrera_v4.tex'
    if ($LASTEXITCODE -ne 0) { throw 'Error de compilación. Consulte el archivo .log.' }
}
