# Script: Ferramenta Avancada de Gerenciamento de Contas AD
# Autor: Voce
# Descricao: Pede um SamAccountName ou UPN, encontra o usuario, e oferece opcoes completas de gerenciamento com log de auditoria detalhado.

param(
    [string]$IdentificadorInicial = $null
)

Import-Module ActiveDirectory -ErrorAction Stop

# --- CONFIGURACAO ---
# Caminho do arquivo de log (agora .csv)
$LogPath = "C:\Logs\AD_Management_Audit.csv"
# Lista de contas criticas que nao podem ser alteradas
$ContasProtegidas = @(
    "administrator",
    "admin",
    "ti.suporte",
    "svc_backup"
)

# --- INICIALIZACAO ---
# Garante que a pasta de logs existe
if (-not (Test-Path (Split-Path $LogPath))) {
    New-Item -ItemType Directory -Path (Split-Path $LogPath) -Force | Out-Null
}

# --- FUNCOES ---
function Registrar-Log {
    param(
        [string]$ContaAlvo,
        [string]$Acao,
        [string]$Status,
        [string]$Detalhes = ""
    )
    try {
        $logEntry = [PSCustomObject]@{
            DataHora     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Executor     = $env:USERNAME
            Hostname     = $env:COMPUTERNAME
            IPLocal      = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '^169\.254' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1 -ExpandProperty IPAddress)
            ContaAlvo    = $ContaAlvo
            Acao         = $Acao
            Status       = $Status.ToUpper()
            Detalhes     = $Detalhes.Replace("`n", " ").Replace("`r", " ")
        }
        if (-not (Test-Path $LogPath)) {
            $logEntry | Export-Csv -Path $LogPath -NoTypeInformation -Encoding UTF8
        } else {
            $logEntry | Export-Csv -Path $LogPath -NoTypeInformation -Append -Encoding UTF8
        }
    } catch {
        Write-Host "ERRO CRITICO: Nao foi possivel escrever no arquivo de log em $LogPath" -ForegroundColor Red
    }
}

function Encontrar-UsuarioAD {
    param([string]$Identificador)
    Write-Host "`nBuscando pelo usuario '$Identificador' no Active Directory..." -ForegroundColor Yellow
    try {
        $Properties = 'DisplayName', 'Department', 'LockedOut', 'Enabled', 'PasswordLastSet', 'LastLogonDate', 'PasswordNeverExpires'
        $Filter = "SamAccountName -eq '$Identificador' -or UserPrincipalName -eq '$Identificador'"
        $Usuario = Get-ADUser -Filter $Filter -Properties $Properties -ErrorAction Stop
        return $Usuario
    } catch {
        Write-Host "ERRO: Nao foi possivel realizar a busca. Verifique a conexao com o AD. ($($_.Exception.Message))" -ForegroundColor Red
        Registrar-Log -ContaAlvo $Identificador -Acao "Busca de Usuario" -Status "FALHA" -Detalhes $_.Exception.Message
        return $null
    }
}

function Desbloquear-Conta {
    param([string]$UsuarioSam)
    if ($UsuarioSam.ToLower() -in $ContasProtegidas) {
        $msg = "A conta e protegida e nao pode ser alterada."
        Write-Host $msg -ForegroundColor Red; Registrar-Log -ContaAlvo $UsuarioSam -Acao "Desbloqueio" -Status "FALHA" -Detalhes $msg; return
    }
    try {
        Unlock-ADAccount -Identity $UsuarioSam -ErrorAction Stop
        Write-Host "Conta $UsuarioSam desbloqueada com sucesso!" -ForegroundColor Green; Registrar-Log -ContaAlvo $UsuarioSam -Acao "Desbloqueio" -Status "SUCESSO"
    } catch { 
        Write-Host "ERRO ao tentar desbloquear ${UsuarioSam}: $($_.Exception.Message)" -ForegroundColor Red
        Registrar-Log -ContaAlvo $UsuarioSam -Acao "Desbloqueio" -Status "FALHA" -Detalhes $_.Exception.Message
    }
}

function Resetar-Senha {
    param([string]$UsuarioSam, [bool]$ForcarTroca, [System.Security.SecureString]$NovaSenha, [string]$TipoReset)
    if ($UsuarioSam.ToLower() -in $ContasProtegidas) {
        $msg = "A conta e protegida e nao pode ser alterada."
        Write-Host $msg -ForegroundColor Red; Registrar-Log -ContaAlvo $UsuarioSam -Acao "Reset de Senha ($TipoReset)" -Status "FALHA" -Detalhes $msg; return $false
    }
    try {
        Set-ADAccountPassword -Identity $UsuarioSam -NewPassword $NovaSenha -Reset -ErrorAction Stop
        Set-ADUser -Identity $UsuarioSam -ChangePasswordAtLogon $ForcarTroca -ErrorAction Stop
        Registrar-Log -ContaAlvo $UsuarioSam -Acao "Reset de Senha ($TipoReset)" -Status "SUCESSO"
        return $true
    } catch { 
        Write-Host "ERRO ao resetar a senha de ${UsuarioSam}: $($_.Exception.Message)" -ForegroundColor Red
        Registrar-Log -ContaAlvo $UsuarioSam -Acao "Reset de Senha ($TipoReset)" -Status "FALHA" -Detalhes $_.Exception.Message
        return $false
    }
}

function Habilitar-Conta {
    param([string]$UsuarioSam)
    if ($UsuarioSam.ToLower() -in $ContasProtegidas) {
        $msg = "A conta e protegida e nao pode ser alterada."
        Write-Host $msg -ForegroundColor Red; Registrar-Log -ContaAlvo $UsuarioSam -Acao "Habilitar Conta" -Status "FALHA" -Detalhes $msg; return
    }
    try {
        Enable-ADAccount -Identity $UsuarioSam -ErrorAction Stop
        Write-Host "Conta $UsuarioSam habilitada com sucesso!" -ForegroundColor Green; Registrar-Log -ContaAlvo $UsuarioSam -Acao "Habilitar Conta" -Status "SUCESSO"
    } catch { 
        Write-Host "ERRO ao tentar habilitar ${UsuarioSam}: $($_.Exception.Message)" -ForegroundColor Red
        Registrar-Log -ContaAlvo $UsuarioSam -Acao "Habilitar Conta" -Status "FALHA" -Detalhes $_.Exception.Message
    }
}

function Desativar-Conta {
    param([string]$UsuarioSam)
    if ($UsuarioSam.ToLower() -in $ContasProtegidas) {
        $msg = "A conta e protegida e nao pode ser alterada."
        Write-Host $msg -ForegroundColor Red; Registrar-Log -ContaAlvo $UsuarioSam -Acao "Desativar Conta" -Status "FALHA" -Detalhes $msg; return
    }
    $confirmacao = Read-Host "Tem certeza que deseja DESATIVAR a conta ${UsuarioSam}? Esta acao impedira o usuario de fazer logon. (S/N)"
    if ($confirmacao -match '^[Ss]$') {
        try {
            Disable-ADAccount -Identity $UsuarioSam -ErrorAction Stop
            Write-Host "Conta $UsuarioSam desativada com sucesso!" -ForegroundColor Green; Registrar-Log -ContaAlvo $UsuarioSam -Acao "Desativar Conta" -Status "SUCESSO"
        } catch { 
            Write-Host "ERRO ao tentar desativar ${UsuarioSam}: $($_.Exception.Message)" -ForegroundColor Red
            Registrar-Log -ContaAlvo $UsuarioSam -Acao "Desativar Conta" -Status "FALHA" -Detalhes $_.Exception.Message
        }
    } else { Write-Host "Operacao de desativacao cancelada." -ForegroundColor Yellow }
}

function Exibir-MenuDeAcoes {
    param([PSCustomObject]$Usuario)
    while ($true) {
        Clear-Host
        Write-Host "==== Gerenciando Usuario ====" -ForegroundColor Cyan
        Write-Host "Nome Completo : $($Usuario.DisplayName)"
        Write-Host "SamAccountName: $($Usuario.SamAccountName)"
        Write-Host "Departamento  : $($Usuario.Department)"
        Write-Host "Status        : Ativo=$($Usuario.Enabled), Bloqueado=$($Usuario.LockedOut)"
        Write-Host "Ultimo Logon  : $($Usuario.LastLogonDate)"
        Write-Host "Senha Expira  : $(if ($Usuario.PasswordNeverExpires) {'Nao'} else {'Sim'})"
        Write-Host "---------------------------------" -ForegroundColor Cyan
        Write-Host "O que voce deseja fazer?"
        Write-Host "1 - Desbloquear conta"
        Write-Host "2 - Resetar senha (Gerada Aleatoriamente)"
        Write-Host "3 - Resetar senha (Personalizada)"
        # --- MELHORIA DE TEXTO APLICADA AQUI ---
        if ($Usuario.Enabled) { 
            Write-Host "4 - Desativar conta" 
        } else { 
            Write-Host "4 - Habilitar (Reativar) conta" 
        }
        Write-Host "5 - Copiar detalhes para area de transferencia"
        Write-Host "0 - Voltar (pesquisar outro usuario)"

        $opcao = Read-Host "Escolha uma opcao"; $AcaoRealizada = $true 
        switch ($opcao) {
            1 {
                if ($Usuario.LockedOut) { Desbloquear-Conta -UsuarioSam $Usuario.SamAccountName } 
                else { Write-Host "A conta ja esta desbloqueada." -ForegroundColor Yellow }
            }
            2 { 
                $prefixoSenha = "HenrySchein@"; $sufixoNumerico = (Get-Random -Minimum 1000 -Maximum 9999)
                $senhaGeradaPlainText = "$prefixoSenha$sufixoNumerico"
                $senhaGeradaSecure = ConvertTo-SecureString $senhaGeradaPlainText -AsPlainText -Force
                $confirmacao = Read-Host "Deseja forcar a troca de senha no proximo logon? (S/N)"; $forcarTroca = $confirmacao -match '^[Ss]$'
                if (Resetar-Senha -UsuarioSam $Usuario.SamAccountName -ForcarTroca $forcarTroca -NovaSenha $senhaGeradaSecure -TipoReset "Aleatoria") {
                    $senhaGeradaPlainText | Set-Clipboard
                    Write-Host "Senha redefinida com sucesso!" -ForegroundColor Green
                    Write-Host "NOVA SENHA GERADA: $senhaGeradaPlainText" -ForegroundColor Magenta
                    Write-Host "A nova senha foi copiada para a area de transferencia." -ForegroundColor Yellow
                    if ($forcarTroca) { Write-Host "A opcao 'Alterar senha no proximo logon' foi ATIVADA." -ForegroundColor Yellow }
                    else { Write-Host "A opcao 'Alterar senha no proximo logon' foi DESATIVADA." -ForegroundColor Yellow }
                }
            }
            3 {
                Write-Host "Digite a nova senha:" -NoNewline; $senhaPersonalizada = Read-Host -AsSecureString
                if ($senhaPersonalizada.Length -eq 0) { Write-Host "A senha nao pode ser vazia. Operacao cancelada." -ForegroundColor Red; break }
                $confirmacao = Read-Host "Deseja forcar a troca de senha no proximo logon? (S/N)"; $forcarTroca = $confirmacao -match '^[Ss]$'
                if (Resetar-Senha -UsuarioSam $Usuario.SamAccountName -ForcarTroca $forcarTroca -NovaSenha $senhaPersonalizada -TipoReset "Personalizada") {
                    Write-Host "Senha redefinida com sucesso!" -ForegroundColor Green
                    if ($forcarTroca) { Write-Host "A opcao 'Alterar senha no proximo logon' foi ATIVADA." -ForegroundColor Yellow }
                    else { Write-Host "A opcao 'Alterar senha no proximo logon' foi DESATIVADA." -ForegroundColor Yellow }
                }
            }
            4 {
                if ($Usuario.Enabled) { Desativar-Conta -UsuarioSam $Usuario.SamAccountName }
                else { Habilitar-Conta -UsuarioSam $Usuario.SamAccountName }
            }
            5 {
                $detalhes = @"
Nome Completo: $($Usuario.DisplayName)
SamAccountName: $($Usuario.SamAccountName)
Departamento: $($Usuario.Department)
Status: Ativo=$($Usuario.Enabled), Bloqueado=$($Usuario.LockedOut)
Ultimo Logon: $($Usuario.LastLogonDate)
"@
                $detalhes | Set-Clipboard; Write-Host "Detalhes do usuario copiados para a area de transferencia." -ForegroundColor Green
            }
            0 { return }
            default { Write-Host "Opcao invalida, tente novamente!" -ForegroundColor Red; $AcaoRealizada = $false }
        }
        
        if ($AcaoRealizada) { Pause }
        $Usuario = Encontrar-UsuarioAD -Identificador $Usuario.SamAccountName
        if (-not $Usuario) { Write-Host "O usuario nao foi mais encontrado. Retornando para a pesquisa principal." -ForegroundColor Red; Pause; return }
    }
}

# --- FLUXO PRINCIPAL DO SCRIPT ---
if (-not [string]::IsNullOrWhiteSpace($IdentificadorInicial)) {
    $UsuarioEncontrado = Encontrar-UsuarioAD -Identificador $IdentificadorInicial
    if ($UsuarioEncontrado) { Exibir-MenuDeAcoes -Usuario $UsuarioEncontrado }
    else { Write-Host "Usuario '$IdentificadorInicial' nao encontrado." -ForegroundColor Red; Pause }
}

while ($true) {
    Clear-Host
    Write-Host "==== Ferramenta de Gerenciamento de Contas AD ====" -ForegroundColor Cyan
    $Entrada = Read-Host "Digite o SamAccountName ou UPN do colaborador (ou 'sair' para fechar)"
    if ($Entrada -eq 'sair') { break }
    if ([string]::IsNullOrWhiteSpace($Entrada)) { continue }

    $UsuarioEncontrado = Encontrar-UsuarioAD -Identificador $Entrada
    if ($UsuarioEncontrado) { Exibir-MenuDeAcoes -Usuario $UsuarioEncontrado }
    else { Write-Host "Usuario '$Entrada' nao encontrado. Verifique se o SamAccountName ou UPN esta correto." -ForegroundColor Red; Pause }
}
Write-Host "Script finalizado." -ForegroundColor Yellow