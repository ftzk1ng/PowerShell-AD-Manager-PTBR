# Script: Iniciar-GerenciadorGUI.ps1 (Front-End Grafico)
# Autor: Voce
# Descricao: Cria a interface grafica para a ferramenta de gerenciamento de contas AD.
# ESTE E O ARQUIVO QUE VOCE DEVE EXECUTAR.

# Carrega as bibliotecas necessarias para a interface grafica
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- PASSO IMPORTANTE: Importa todas as funcoes do seu script principal ---
# O ponto no inicio (dot-sourcing) carrega as funcoes do back-end.
# Garante que o script Gerenciador-AD.ps1 esteja na mesma pasta.
try {
    . (Join-Path $PSScriptRoot "Gerenciador-AD.ps1")
} catch {
    [System.Windows.Forms.MessageBox]::Show("ERRO CRITICO: O arquivo 'Gerenciador-AD.ps1' nao foi encontrado na mesma pasta. O programa nao pode continuar.", "Erro de Inicializacao", "OK", "Error")
    exit
}

# --- Funcao que cria a janela de Edicao de Atributos ---
function Show-EditAttributesWindow {
    param([PSCustomObject]$Usuario)
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Editando Atributos de $($Usuario.DisplayName)"
    $form.Size = New-Object System.Drawing.Size(400, 200)
    $form.StartPosition = "CenterParent"
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false

    $labelDept = New-Object System.Windows.Forms.Label; $labelDept.Location = "20,20"; $labelDept.Text = "Departamento:"
    $textDept = New-Object System.Windows.Forms.TextBox; $textDept.Location = "20,40"; $textDept.Size = "340,20"; $textDept.Text = $Usuario.Department
    
    $labelTel = New-Object System.Windows.Forms.Label; $labelTel.Location = "20,80"; $labelTel.Text = "Telefone:"
    $textTel = New-Object System.Windows.Forms.TextBox; $textTel.Location = "20,100"; $textTel.Size = "340,20"; $textTel.Text = $Usuario.OfficePhone

    $buttonSalvar = New-Object System.Windows.Forms.Button; $buttonSalvar.Location = "190,140"; $buttonSalvar.Size = "80,25"; $buttonSalvar.Text = "Salvar"
    $buttonCancelar = New-Object System.Windows.Forms.Button; $buttonCancelar.Location = "280,140"; $buttonCancelar.Size = "80,25"; $buttonCancelar.Text = "Cancelar"
    
    $buttonSalvar.Add_Click({
        if (Set-AtributosUsuarioAD -UsuarioSam $Usuario.SamAccountName -Departamento $textDept.Text -Telefone $textTel.Text) {
            [System.Windows.Forms.MessageBox]::Show("Atributos atualizados com sucesso!", "Sucesso", "OK", "Information")
            $form.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show("Falha ao atualizar os atributos. Verifique o log.", "Erro", "OK", "Error")
        }
    })
    $buttonCancelar.Add_Click({ $form.Close() })

    $form.Controls.AddRange(@($labelDept, $textDept, $labelTel, $textTel, $buttonSalvar, $buttonCancelar))
    $form.ShowDialog() | Out-Null
}

# --- Funcao que cria a janela de Lista de Resultados ---
function Show-ResultsWindow {
    param([array]$UsuariosEncontrados)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Resultados da Busca - Selecione um Usuario"
    $form.Size = New-Object System.Drawing.Size(600, 400)
    $form.StartPosition = "CenterParent"
    
    $listView = New-Object System.Windows.Forms.ListView
    $listView.Location = New-Object System.Drawing.Point(15, 15)
    $listView.Size = New-Object System.Drawing.Size(550, 280)
    $listView.View = "Details"
    $listView.FullRowSelect = $true
    $listView.MultiSelect = $false

    $listView.Columns.Add("Nome de Exibicao", 250) | Out-Null
    $listView.Columns.Add("Nome de Usuario", 150) | Out-Null
    $listView.Columns.Add("Departamento", 150) | Out-Null

    foreach ($usuario in $UsuariosEncontrados) {
        $item = New-Object System.Windows.Forms.ListViewItem($usuario.DisplayName)
        $item.SubItems.Add($usuario.SamAccountName) | Out-Null
        $item.SubItems.Add($usuario.Department) | Out-Null
        $item.Tag = $usuario
        $listView.Items.Add($item) | Out-Null
    }

    $buttonSelecionar = New-Object System.Windows.Forms.Button; $buttonSelecionar.Location = "350,310"; $buttonSelecionar.Size = "100,30"; $buttonSelecionar.Text = "Selecionar"; $buttonSelecionar.Enabled = $false; $buttonSelecionar.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $buttonCancelar = New-Object System.Windows.Forms.Button; $buttonCancelar.Location = "465,310"; $buttonCancelar.Size = "100,30"; $buttonCancelar.Text = "Cancelar"; $buttonCancelar.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $buttonSelecionar.Add_Click({ $form.Close() }); $buttonCancelar.Add_Click({ $form.Close() })
    $listView.Add_SelectedIndexChanged({ $buttonSelecionar.Enabled = $true })
    $listView.Add_DoubleClick({ if ($listView.SelectedItems.Count -gt 0) { $buttonSelecionar.PerformClick() }})

    $form.Controls.AddRange(@($listView, $buttonSelecionar, $buttonCancelar))
    
    if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        if ($listView.SelectedItems.Count -gt 0) {
            return $listView.SelectedItems[0].Tag
        }
    }
    return $null
}

# --- Funcao que cria a janela de Acoes para um usuario especifico ---
function Show-ActionsWindow {
    param([PSCustomObject]$Usuario)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Gerenciando: $($Usuario.DisplayName)"
    $form.Size = New-Object System.Drawing.Size(500, 560)
    $form.StartPosition = "CenterScreen"; $form.FormBorderStyle = 'FixedDialog'; $form.MaximizeBox = $false

    $groupDetalhes = New-Object System.Windows.Forms.GroupBox; $groupDetalhes.Location = "15,15"; $groupDetalhes.Size = "450,220"; $groupDetalhes.Text = "Detalhes do Usuario"; $form.Controls.Add($groupDetalhes)
    $groupAcoes = New-Object System.Windows.Forms.GroupBox; $groupAcoes.Location = "15,250"; $groupAcoes.Size = "450,250"; $groupAcoes.Text = "Acoes"; $form.Controls.Add($groupAcoes)

    $fontBold = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $labels = @{}
    $propriedades = @{"Nome Completo:" = $Usuario.DisplayName; "SamAccountName:" = $Usuario.SamAccountName; "Departamento:" = $Usuario.Department; "Telefone:" = $Usuario.OfficePhone; "Status:" = "Ativo=$($Usuario.Enabled), Bloqueado=$($Usuario.LockedOut)"; "Ultimo Logon:" = $Usuario.LastLogonDate; "Senha Expira:" = $(if ($Usuario.PasswordNeverExpires) {'Nao'} else {'Sim'})}
    $yPos = 30
    foreach ($prop in $propriedades.GetEnumerator()) {
        $labelStatic = New-Object System.Windows.Forms.Label; $labelStatic.Location = "20,$yPos"; $labelStatic.Size = "120,20"; $labelStatic.Text = $prop.Name; $groupDetalhes.Controls.Add($labelStatic)
        $labelDynamic = New-Object System.Windows.Forms.Label; $labelDynamic.Location = "140,$yPos"; $labelDynamic.Size = "290,20"; $labelDynamic.Font = $fontBold; $labelDynamic.Text = $prop.Value; $groupDetalhes.Controls.Add($labelDynamic)
        $labels[$prop.Name] = $labelDynamic
        $yPos += 25
    }

    function Update-UserDetails {
        $currentUser = Buscar-UsuariosAD -TermoBusca $Usuario.SamAccountName | Where-Object { $_.SamAccountName -eq $Usuario.SamAccountName }
        if ($currentUser) {
            $Usuario = $currentUser
            $labels["Departamento:"].Text = $Usuario.Department; $labels["Telefone:"].Text = $Usuario.OfficePhone; $labels["Status:"].Text = "Ativo=$($Usuario.Enabled), Bloqueado=$($Usuario.LockedOut)"
            $buttonEnableDisable.Text = if ($Usuario.Enabled) { "Desativar Conta" } else { "Habilitar (Reativar) Conta" }; $buttonUnlock.Enabled = $Usuario.LockedOut
        }
    }

    $buttonUnlock = New-Object System.Windows.Forms.Button; $buttonUnlock.Location = "20,40"; $buttonUnlock.Size = "200,30"; $buttonUnlock.Text = "Desbloquear Conta"; $buttonUnlock.Enabled = $Usuario.LockedOut
    $buttonUnlock.Add_Click({ if (Desbloquear-Conta -UsuarioSam $Usuario.SamAccountName) {[System.Windows.Forms.MessageBox]::Show("Conta desbloqueada com sucesso!", "Sucesso", "OK", "Information"); Update-UserDetails} else {[System.Windows.Forms.MessageBox]::Show("Falha ao desbloquear a conta. Verifique o log.", "Erro", "OK", "Error")} }); $groupAcoes.Controls.Add($buttonUnlock)
    
    $buttonResetRandom = New-Object System.Windows.Forms.Button; $buttonResetRandom.Location = "20,80"; $buttonResetRandom.Size = "200,30"; $buttonResetRandom.Text = "Resetar Senha (Aleatoria)"
    $buttonResetRandom.Add_Click({
        $senhaGerada = Gerar-SenhaAleatoria; $senhaSecure = ConvertTo-SecureString $senhaGerada -AsPlainText -Force
        $resultado = [System.Windows.Forms.MessageBox]::Show("Forcar troca de senha no proximo logon?", "Confirmacao", "YesNo", "Question"); $forcarTroca = ($resultado -eq "Yes")
        if (Resetar-Senha -UsuarioSam $Usuario.SamAccountName -ForcarTroca $forcarTroca -NovaSenha $senhaSecure -TipoReset "Aleatoria") {[System.Windows.Forms.Clipboard]::SetText($senhaGerada);[System.Windows.Forms.MessageBox]::Show("Senha redefinida com sucesso! `nNOVA SENHA: $senhaGerada `n(A senha foi copiada para a area de transferencia)", "Sucesso", "OK", "Information")}
        else {[System.Windows.Forms.MessageBox]::Show("Falha ao resetar a senha.", "Erro", "OK", "Error")}
    }); $groupAcoes.Controls.Add($buttonResetRandom)
    
    $buttonResetCustom = New-Object System.Windows.Forms.Button; $buttonResetCustom.Location = "20,120"; $buttonResetCustom.Size = "200,30"; $buttonResetCustom.Text = "Resetar Senha (Personalizada)"
    $buttonResetCustom.Add_Click({
        $prompt = New-Object System.Windows.Forms.Form; $prompt.Width = 300; $prompt.Height = 150; $prompt.Text = "Digite a Nova Senha"; $prompt.StartPosition = "CenterParent"
        $textLabel = New-Object System.Windows.Forms.Label; $textLabel.Left = 20; $textLabel.Top = 20; $textLabel.Text = "Nova Senha:"
        $textBox = New-Object System.Windows.Forms.TextBox; $textBox.Left = 20; $textBox.Top = 40; $textBox.Width = 240; $textBox.UseSystemPasswordChar = $true
        $confirmation = New-Object System.Windows.Forms.Button; $confirmation.Text = "OK"; $confirmation.Left = 160; $confirmation.Top = 70; $confirmation.Add_Click({$prompt.Close()})
        $prompt.Controls.AddRange(@($confirmation, $textLabel, $textBox)); $prompt.ShowDialog() | Out-Null
        if ($textBox.Text.Length -gt 0) {
            $senhaSecure = ConvertTo-SecureString $textBox.Text -AsPlainText -Force; $resultado = [System.Windows.Forms.MessageBox]::Show("Forcar troca de senha no proximo logon?", "Confirmacao", "YesNo", "Question"); $forcarTroca = ($resultado -eq "Yes")
            if (Resetar-Senha -UsuarioSam $Usuario.SamAccountName -ForcarTroca $forcarTroca -NovaSenha $senhaSecure -TipoReset "Personalizada") {[System.Windows.Forms.MessageBox]::Show("Senha redefinida com sucesso!", "Sucesso", "OK", "Information")}
            else {[System.Windows.Forms.MessageBox]::Show("Falha ao resetar a senha.", "Erro", "OK", "Error")}
        }
    }); $groupAcoes.Controls.Add($buttonResetCustom)
    
    $buttonEnableDisable = New-Object System.Windows.Forms.Button; $buttonEnableDisable.Location = "20,160"; $buttonEnableDisable.Size = "200,30"; $buttonEnableDisable.Text = if ($Usuario.Enabled) { "Desativar Conta" } else { "Habilitar (Reativar) Conta" }
    $buttonEnableDisable.Add_Click({
        if ($Usuario.Enabled) {
            if ([System.Windows.Forms.MessageBox]::Show("Tem certeza que deseja DESATIVAR esta conta?", "Confirmar Desativacao", "YesNo", "Warning") -eq "Yes") {
                if (Desativar-Conta -UsuarioSam $Usuario.SamAccountName) {[System.Windows.Forms.MessageBox]::Show("Conta desativada com sucesso!", "Sucesso", "OK", "Information"); Update-UserDetails} else {[System.Windows.Forms.MessageBox]::Show("Falha ao desativar a conta.", "Erro", "OK", "Error")}
            }
        } else {
            if (Habilitar-Conta -UsuarioSam $Usuario.SamAccountName) {[System.Windows.Forms.MessageBox]::Show("Conta habilitada com sucesso!", "Sucesso", "OK", "Information"); Update-UserDetails} else {[System.Windows.Forms.MessageBox]::Show("Falha ao habilitar a conta.", "Erro", "OK", "Error")}
        }
    }); $groupAcoes.Controls.Add($buttonEnableDisable)

    $buttonEdit = New-Object System.Windows.Forms.Button; $buttonEdit.Location = "240,40"; $buttonEdit.Size = "200,30"; $buttonEdit.Text = "Editar Atributos (Dept/Tel)"
    $buttonEdit.Add_Click({ Show-EditAttributesWindow -Usuario $Usuario; Update-UserDetails }); $groupAcoes.Controls.Add($buttonEdit)
    
    $buttonCopy = New-Object System.Windows.Forms.Button; $buttonCopy.Location = "20,200"; $buttonCopy.Size = "200,30"; $buttonCopy.Text = "Copiar Detalhes"
    $buttonCopy.Add_Click({
        $detalhes = @"
Nome Completo: $($Usuario.DisplayName); SamAccountName: $($Usuario.SamAccountName); Departamento: $($Usuario.Department); Telefone: $($Usuario.OfficePhone); Status: Ativo=$($Usuario.Enabled), Bloqueado=$($Usuario.LockedOut); Ultimo Logon: $($Usuario.LastLogonDate)
"@
        [System.Windows.Forms.Clipboard]::SetText($detalhes); [System.Windows.Forms.MessageBox]::Show("Detalhes do usuario copiados para a area de transferencia.", "Copiado", "OK", "Information")
    }); $groupAcoes.Controls.Add($buttonCopy)

    $buttonVoltar = New-Object System.Windows.Forms.Button; $buttonVoltar.Location = "365,500"; $buttonVoltar.Size = "100,30"; $buttonVoltar.Text = "Voltar"; $buttonVoltar.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $buttonVoltar.Add_Click({ $form.Close() }); $form.Controls.Add($buttonVoltar)

    $form.ShowDialog() | Out-Null
}

# --- Funcao que cria e exibe a janela principal de Busca ---
function Show-MainWindow {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Ferramenta de Gerenciamento AD"; $form.Size = "420,180"; $form.StartPosition = "CenterScreen"; $form.FormBorderStyle = 'FixedDialog'; $form.MaximizeBox = $false
    
    $label = New-Object System.Windows.Forms.Label; $label.Location = "20,20"; $label.Size = "360,20"; $label.Text = "Digite o nome (ou parte) do colaborador:"
    $textBox = New-Object System.Windows.Forms.TextBox; $textBox.Location = "20,45"; $textBox.Size = "250,20"
    $buttonSearch = New-Object System.Windows.Forms.Button; $buttonSearch.Location = "280,43"; $buttonSearch.Size = "100,25"; $buttonSearch.Text = "Buscar"
    $labelStatus = New-Object System.Windows.Forms.Label; $labelStatus.Location = "20,90"; $labelStatus.Size = "360,20"; $labelStatus.Text = "Aguardando busca..."
    
    $searchAction = {
        $termoBusca = $textBox.Text
        if ([string]::IsNullOrWhiteSpace($termoBusca)) { $labelStatus.Text = "Por favor, digite um termo para a busca."; $labelStatus.ForeColor = "Red"; return }
        $labelStatus.Text = "Buscando..."; $labelStatus.ForeColor = "Blue"; $form.Refresh()
        $usuariosEncontrados = Buscar-UsuariosAD -TermoBusca $termoBusca
        $usuarioSelecionado = $null
        if ($usuariosEncontrados.Count -eq 0) { $labelStatus.Text = "Nenhum usuario encontrado para '$termoBusca'."; $labelStatus.ForeColor = "Red"; return } 
        elseif ($usuariosEncontrados.Count -eq 1) { $usuarioSelecionado = $usuariosEncontrados[0] } 
        else { $form.Hide(); $usuarioSelecionado = Show-ResultsWindow -UsuariosEncontrados $usuariosEncontrados; $form.Show() }

        if ($usuarioSelecionado) {
            $form.Hide(); Show-ActionsWindow -Usuario $usuarioSelecionado
            $textBox.Text = ""; $labelStatus.Text = "Aguardando nova busca..."; $labelStatus.ForeColor = "Black"; $form.Show(); $textBox.Focus()
        } else { 
            # --- CORRECAO APLICADA AQUI ---
            $labelStatus.Text = "Aguardando nova busca... (Operacao cancelada ou nenhum usuario selecionado)"; $labelStatus.ForeColor = "Black" 
        }
    }
    $buttonSearch.Add_Click($searchAction)
    $textBox.Add_KeyDown({ if ($_.KeyCode -eq "Enter") { &$searchAction } })

    $form.Controls.AddRange(@($label, $textBox, $buttonSearch, $labelStatus))
    $form.ShowDialog() | Out-Null
}

# --- Ponto de Entrada: Chama a funcao para mostrar a janela de busca ---
Show-MainWindow