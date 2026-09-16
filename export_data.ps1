# Exporta os dados da planilha "FECHAMENTO CONSERTO LT 2026.xlsx" para dashboard/data.js
# Rode este script sempre que quiser atualizar o dashboard HTML com os lancamentos mais recentes.
# Depois e so subir (git add / commit / push) a pasta "dashboard" para o GitHub.

$ErrorActionPreference = "Stop"
$xlsxPath = Join-Path $PSScriptRoot "..\FECHAMENTO CONSERTO LT 2026.xlsx"
$xlsxPath = (Resolve-Path $xlsxPath).Path
$outPath  = Join-Path $PSScriptRoot "data.js"

Write-Output "Lendo planilha: $xlsxPath"

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

try {
    $wb = $excel.Workbooks.Open($xlsxPath, [Type]::Missing, $true) # read-only
    $data = $wb.Worksheets.Item("_DadosDashboard")

    $months = @()
    $bruto = @(); $custo = @(); $lucro = @(); $alex = @(); $empresa = @()
    $dinheiro = @(); $credito = @(); $debito = @(); $pix = @(); $qtdOS = @()

    for ($row = 2; $row -le 13; $row++) {
        $months   += [string]$data.Cells.Item($row,1).Value2
        $bruto    += [double]$data.Cells.Item($row,2).Value2
        $custo    += [double]$data.Cells.Item($row,3).Value2
        $lucro    += [double]$data.Cells.Item($row,4).Value2
        $alex     += [double]$data.Cells.Item($row,5).Value2
        $empresa  += [double]$data.Cells.Item($row,6).Value2
        $dinheiro += [double]$data.Cells.Item($row,7).Value2
        $credito  += [double]$data.Cells.Item($row,8).Value2
        $debito   += [double]$data.Cells.Item($row,9).Value2
        $pix      += [double]$data.Cells.Item($row,10).Value2
        $qtdOS    += [int]$data.Cells.Item($row,11).Value2
    }

    $totals = [ordered]@{
        bruto    = [double]$data.Cells.Item(14,2).Value2
        custo    = [double]$data.Cells.Item(14,3).Value2
        lucro    = [double]$data.Cells.Item(14,4).Value2
        alex     = [double]$data.Cells.Item(14,5).Value2
        empresa  = [double]$data.Cells.Item(14,6).Value2
        dinheiro = [double]$data.Cells.Item(14,7).Value2
        credito  = [double]$data.Cells.Item(14,8).Value2
        debito   = [double]$data.Cells.Item(14,9).Value2
        pix      = [double]$data.Cells.Item(14,10).Value2
        qtdOS    = [int]$data.Cells.Item(14,11).Value2
    }

    $obj = [ordered]@{
        geradoEm = (Get-Date).ToString("yyyy-MM-dd HH:mm")
        meses    = $months
        bruto    = $bruto
        custo    = $custo
        lucro    = $lucro
        alex     = $alex
        empresa  = $empresa
        dinheiro = $dinheiro
        credito  = $credito
        debito   = $debito
        pix      = $pix
        qtdOS    = $qtdOS
        totais   = $totals
    }

    $json = $obj | ConvertTo-Json -Depth 5
    $js = "// Gerado automaticamente por export_data.ps1 - nao editar a mao`nconst DASHBOARD_DATA = " + $json + ";`n"

    [System.IO.File]::WriteAllText($outPath, $js, [System.Text.Encoding]::UTF8)

    Write-Output "OK - data.js atualizado em: $outPath"
    Write-Output ("Total Bruto Ano: " + $totals.bruto)

} finally {
    if ($wb) { $wb.Close($false) }
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
