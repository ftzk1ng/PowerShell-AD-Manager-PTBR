# Ferramenta Gráfica de Gerenciamento de Contas Active Directory

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue) ![Framework](https://img.shields.io/badge/UI-Windows%20Forms-orange)

Transforme a gestão de contas do dia a dia no Active Directory em uma experiência visual, rápida e intuitiva. Esta aplicação, construída sobre um poderoso back-end em PowerShell, oferece uma interface gráfica completa para eliminar a necessidade de comandos e cliques repetitivos no ADUC.

---

## Screenshot da Aplicação

<img width="399" height="168" alt="image" src="https://github.com/user-attachments/assets/c9eb30f4-1175-4513-88b1-d945ec9c794b" />
<img width="483" height="526" alt="image" src="https://github.com/user-attachments/assets/f77c80dd-cd05-4457-b2b0-f69afddd3e9b" />


---

### Por que uma Interface Gráfica?

A evolução deste projeto para uma GUI foi focada em adiantar ainda mais os processos da equipe de TI, oferecendo:

*   **Acessibilidade Total:** Não é preciso ser um expert em PowerShell. Qualquer membro da equipe, do júnior ao sênior, pode usar a ferramenta com segurança e confiança.
*   **Eficiência e Velocidade:** A busca parcial com lista de resultados, combinada com botões de ação claros, torna o fluxo de trabalho muito mais rápido do que navegar por menus e propriedades no ADUC.
*   **Redução de Erros:** Menus visuais e caixas de confirmação minimizam o risco de erros de digitação ou ações acidentais, como desativar a conta errada.
*   **Curva de Aprendizagem Zero:** A interface é intuitiva e autoexplicativa, eliminando a necessidade de treinamento extensivo.

---

## Funcionalidades Principais

✔️ **Busca Flexível com Múltiplos Resultados:** Procure por parte do nome, `SamAccountName` ou UPN e selecione o usuário correto em uma lista clara e organizada.

✔️ **Gerenciamento Completo de Contas:**
  - **Desbloqueio** de contas com um único clique.
  - **Habilitação (Reativação)** e **Desabilitação** de contas com um menu inteligente e passo de confirmação para evitar acidentes.
  - **Edição de Atributos:** Altere o Departamento e o Telefone do usuário em uma janela de edição dedicada.

✔️ **Reset de Senha Seguro e Flexível:**
  - **Geração Aleatória:** Crie senhas temporárias seguras, que são exibidas na tela e copiadas para a área de transferência.
  - **Senha Personalizada:** Defina uma senha específica de forma segura através de um campo mascarado.
  - **Opção de Troca no Próximo Logon:** Decida interativamente se o usuário deve ou não alterar a senha ao logar.

✔️ **Auditoria Detalhada:**
  - Todas as ações (sucessos e falhas) são registradas em um arquivo **CSV** estruturado.
  - O log captura quem executou a ação, de qual computador (hostname e IP), quando, em qual conta alvo, e o resultado.

✔️ **Interface Intuitiva:**
  - Exibição clara de detalhes importantes como data do último logon e status de expiração da senha.
  - **Copiar Detalhes:** Copie um resumo das informações do usuário para a área de transferência, ideal para colar em tickets de suporte.

---

## Pré-requisitos

1.  **Windows PowerShell 5.1** ou superior.
2.  **Módulo Active Directory para Windows PowerShell:**
    - Geralmente instalado com as Ferramentas de Administração de Servidor Remoto (RSAT).
3.  **Permissões:** A aplicação deve ser executada com uma conta que tenha permissões para ler e modificar usuários no Active Directory.

---

## Como Usar

A aplicação é composta por dois arquivos que devem estar **na mesma pasta**:
*   `Gerenciador-AD.ps1` (o back-end com a lógica)
*   `Iniciar-GerenciadorGUI.ps1` (o front-end que você executa)

1.  **Execução Principal:**
    - O método recomendado é executar o arquivo `Iniciar-GerenciadorGUI.ps1`.
    - Clique com o botão direito no arquivo e selecione "Executar com o PowerShell". A interface gráfica será iniciada.

2.  **Criando um Atalho para Facilitar a Distribuição:**
    - Crie um atalho na área de trabalho.
    - No campo "Destino", use o seguinte comando, ajustando o caminho para o seu arquivo:
      ```
      powershell.exe -NoExit -ExecutionPolicy Bypass -File "C:\Caminho\Para\Seus\Scripts\Iniciar-GerenciadorGUI.ps1"
      ```
    - Nas propriedades avançadas do atalho, marque **"Executar como administrador"**.

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
