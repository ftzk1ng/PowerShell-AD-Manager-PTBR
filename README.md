# Ferramenta de Gerenciamento de Contas Active Directory em PowerShell

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)

Uma ferramenta de linha de comando poderosa e interativa, criada para administradores de sistema, que agiliza e protege as tarefas mais comuns de gerenciamento de contas no Active Directory. Diga adeus a cliques repetitivos no ADUC!

---

## Funcionalidades Principais

✔️ **Busca Rápida e Precisa:** Encontre usuários instantaneamente pelo `SamAccountName` ou `UserPrincipalName` (UPN).

✔️ **Gerenciamento Completo de Contas:**
  - **Desbloqueio** de contas com um único comando.
  - **Habilitação (Reativação)** e **Desabilitação** de contas com um menu inteligente e passo de confirmação para evitar acidentes.

✔️ **Reset de Senha Seguro e Flexível:**
  - **Geração Aleatória:** Crie senhas temporárias seguras com um prefixo padrão e números aleatórios, que são exibidas na tela e copiadas para a área de transferência.
  - **Senha Personalizada:** Defina uma senha específica de forma segura, sem exibi-la na tela.
  - **Opção de Troca no Próximo Logon:** Decida interativamente se o usuário deve ou não alterar a senha ao logar.

✔️ **Auditoria Detalhada:**
  - Todas as ações (sucessos e falhas) são registradas em um arquivo **txt** estruturado.
  - O log captura quem executou a ação, de qual computador (hostname e IP), quando, em qual conta alvo, e o resultado (incluindo mensagens de erro).

✔️ **Interface Intuitiva:**
  - Um menu de ações claro e contextualizado para cada usuário.
  - Exibição de detalhes importantes como data do último logon e status de expiração da senha.
  - Permanece no menu do usuário após uma ação, permitindo múltiplas operações sem nova pesquisa.

✔️ **Segurança e Agilidade:**
  - **Lista de Contas Protegidas:** Evita alterações acidentais em contas de serviço e administradores.
  - **Execução por Parâmetro:** Inicie o script e vá direto para a tela de um usuário específico (`.\Gerenciador-AD.ps1 nome.usuario`).
  - **Copiar Detalhes:** Copie um resumo das informações do usuário para a área de transferência, ideal para colar em tickets de suporte.

---

## Pré-requisitos

1.  **Windows PowerShell 5.1** ou superior.
2.  **Módulo Active Directory para Windows PowerShell:**
    - Geralmente instalado com as Ferramentas de Administração de Servidor Remoto (RSAT).
3.  **Permissões:** O script deve ser executado com uma conta que tenha permissões para ler e modificar usuários no Active Directory.

---

## Como Usar

1.  **Download:** Baixe o script `Gerenciador-AD.ps1` deste repositório.

2.  **Personalização (Opcional):**
    - Abra o script e edite a lista `$ContasProtegidas` para incluir as contas críticas do seu ambiente.
    - Altere o prefixo da senha aleatória na função `Exibir-MenuDeAcoes` (atualmente "SuaEmpresa@").

3.  **Execução:**
    - Clique com o botão direito no arquivo `.ps1` e selecione "Executar com o PowerShell".
    - **Recomendado:** Abra uma janela do PowerShell como Administrador, navegue até a pasta do script e execute:
      ```powershell
      .\Gerenciador-AD.ps1
      ```

4.  **Execução Rápida com Parâmetro:**
    Para ir direto a um usuário, execute o script passando o SamAccountName ou UPN:
    ```powershell
    .\Gerenciador-AD.ps1 usuario.alvo
    ```

5.  **Criando um Atalho:**
    - Crie um atalho na área de trabalho.
    - No campo "Destino", use o seguinte comando (ajuste o caminho do arquivo):
      ```
      powershell.exe -NoExit -ExecutionPolicy Bypass -File "C:\Scripts\Gerenciador-AD.ps1"
      ```
    - Nas propriedades avançadas do atalho, marque "Executar como administrador".

---

## Estrutura do Log de Auditoria (`.csv`)

O arquivo de log gerado pode ser aberto no Excel e contém as seguintes colunas para fácil filtragem e análise:

| Coluna       | Descrição                                                     |
|--------------|---------------------------------------------------------------|
| `DataHora`     | Data e hora exatas em que a ação foi executada.               |
| `Executor`     | Nome de usuário do administrador que executou o script.       |
| `Hostname`     | Nome do computador de onde o script foi executado.            |
| `IPLocal`      | Endereço IP do computador do administrador.                   |
| `ContaAlvo`    | O SamAccountName do usuário que sofreu a ação.                |
| `Acao`         | A operação realizada (ex: Desbloqueio, Reset de Senha, etc.). |
| `Status`       | O resultado da operação (`SUCESSO` ou `FALHA`).               |
| `Detalhes`     | Mensagem de erro específica em caso de falha.                 |

---

## Licença

Este projeto é licenciado sob a Licença MIT.

Projeto criado utilizando conhecimentos básicos em powershell com auxilio do Gemini 2.5 PRO, pretendo futuramente incluir novas funcionalidades, como a inclusão e remoção de grupos, criar uma interface gráfica para o projeto e geração de logs em planilhas CSV, não em .txt
