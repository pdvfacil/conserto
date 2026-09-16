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

# Le uma celula numerica com seguranca: se a celula estiver com erro de formula
# (#REF!, #DIV/0!, #VALUE! etc.) aborta o script em vez de gravar um numero
# corrompido por cima do data.js bom que ja existe.
function Get-SafeNumber {
    param($Cell, [string]$Label)
    if ($Cell.Text -like "#*") {
        throw "Celula com erro de formula ($($Cell.Text)) em '$Label' (linha $($Cell.Row), coluna $($Cell.Column)). Corrija a planilha antes de exportar - nada foi gravado."
    }
    return [double]$Cell.Value2
}

try {
    $wb = $excel.Workbooks.Open($xlsxPath, [Type]::Missing, $true) # read-only
    $data = $wb.Worksheets.Item("_DadosDashboard")

    $months = @()
    $bruto = @(); $custo = @(); $lucro = @(); $alex = @(); $empresa = @()
    $dinheiro = @(); $credito = @(); $debito = @(); $pix = @(); $qtdOS = @()

    for ($row = 2; $row -le 13; $row++) {
        $months   += [string]$data.Cells.Item($row,1).Value2
        $bruto    += Get-SafeNumber $data.Cells.Item($row,2) "Bruto"
        $custo    += Get-SafeNumber $data.Cells.Item($row,3) "Custo"
        $lucro    += Get-SafeNumber $data.Cells.Item($row,4) "Lucro"
        $alex     += Get-SafeNumber $data.Cells.Item($row,5) "Alex"
        $empresa  += Get-SafeNumber $data.Cells.Item($row,6) "Empresa"
        $dinheiro += Get-SafeNumber $data.Cells.Item($row,7) "Dinheiro"
        $credito  += Get-SafeNumber $data.Cells.Item($row,8) "Credito"
        $debito   += Get-SafeNumber $data.Cells.Item($row,9) "Debito"
        $pix      += Get-SafeNumber $data.Cells.Item($row,10) "Pix"
        $qtdOS    += [int](Get-SafeNumber $data.Cells.Item($row,11) "QtdOS")
    }

    $totals = [ordered]@{
        bruto    = Get-SafeNumber $data.Cells.Item(14,2) "Total Bruto"
        custo    = Get-SafeNumber $data.Cells.Item(14,3) "Total Custo"
        lucro    = Get-SafeNumber $data.Cells.Item(14,4) "Total Lucro"
        alex     = Get-SafeNumber $data.Cells.Item(14,5) "Total Alex"
        empresa  = Get-SafeNumber $data.Cells.Item(14,6) "Total Empresa"
        dinheiro = Get-SafeNumber $data.Cells.Item(14,7) "Total Dinheiro"
        credito  = Get-SafeNumber $data.Cells.Item(14,8) "Total Credito"
        debito   = Get-SafeNumber $data.Cells.Item(14,9) "Total Debito"
        pix      = Get-SafeNumber $data.Cells.Item(14,10) "Total Pix"
        qtdOS    = [int](Get-SafeNumber $data.Cells.Item(14,11) "Total QtdOS")
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

    # Guarda uma copia do data.js anterior antes de sobrescrever, para poder
    # restaurar rapido se algo sair errado.
    if (Test-Path $outPath) {
        Copy-Item -Path $outPath -Destination (Join-Path $PSScriptRoot "data.js.bak") -Force
    }

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
