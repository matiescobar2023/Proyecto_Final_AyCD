$ErrorActionPreference = 'Stop'
Push-Location -LiteralPath $PSScriptRoot
try {
    $compiler = Get-Command pdflatex -ErrorAction SilentlyContinue
    $compilerPath = if ($compiler) { $compiler.Source } else { $null }
    if (-not $compilerPath) {
        $candidates = @(
            (Join-Path $env:LOCALAPPDATA 'Programs\MiKTeX\miktex\bin\x64\pdflatex.exe'),
            'C:\Program Files\MiKTeX\miktex\bin\x64\pdflatex.exe'
        )
        $compilerPath = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    }
    if (-not $compilerPath) { throw 'Instale MiKTeX o TeX Live y agregue pdfLaTeX al PATH.' }
    1..3 | ForEach-Object {
        & $compilerPath -interaction=nonstopmode -halt-on-error 'Informe_AyCD_EscobarHerrera_v3.tex'
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo compilar. Consulte el archivo .log.' }
    }
}
finally { Pop-Location }
