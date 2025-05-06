# Bootcamp Google e Tigabytes

Estes arquivos serão utilizados durante o bootcamp promovido pelo Google e a Tigabytes para startups.

## 🚀 Começando

Neste laboratório iremos implementar um ambiente ficticio que será utilizado demonstrar o funcionamento do Security Command Center e do Cloud Armor.

### 📋 Pré-requisitos

Conta de Acesso com permissões para implmentação dos componentes abaixo em sua conta GCP:
- Compute Engine
- Instance Templates
- Managed Instances Group
- Cloud Storage
- Cloud Spanner
- Cloud Load Balancer
- Cloud Network VPC e Subnets
- Cloud Firewall Rules
- Cloud Armor
- Cloud Security Command Center

Verifique se as APIs relacionadas aos serviços acima estão devidamente habilitadas em seu projeto.
- Cloud Spanner API (https://console.cloud.google.com/apis/library/spanner.googleapis.com)
- Google Cloud Memorystore for Redis API (https://console.cloud.google.com/apis/library/redis.googleapis.com)
- Service Usage API (https://console.cloud.google.com/apis/library/serviceusage.googleapis.com)

### 🔧 Instalação

1. Faça login em seu console do GCP
2. Abra o Terminal (>_) localizado no menu superior direito
3. Faça o download dos arquivos disponíveis no Github do bootcamp com o comando: wget https://github.com/tigabytes-jpereira/bootcamp_google_tigabytes/archive/refs/heads/main.zip
4. Descompacte o arquivo com o comando abaixo: unzip main.zip
5. Abra o diretório criado: cd bootcamp_google_tigabytes-main
6. Nele estarão contidos todos os arquivos necessários para este lab
7. Abra o Editor ("Open Editor) disponivel na barra de opções do Terminal e abra o arquivo "variables.tf"
8. Altere os valores das variáveis "project", "region", "zone" e "bucket_name" de acordo com seu ambiente e salve as alterações com Ctrl+S.
9. Volte ao Terminal (Open Terminal)
10. Inicialize o Terraform executando o comando: terraform init
11. Execute o comando a seguir para iniciar o processo de validação dos arquivos e está tudo pronto para criar o ambiente: terraform plan
12. Se tudo estiver ok, será exibido algo parecido com essa saída:
    Plan: 32 to add, 0 to change, 0 to destroy.

    Changes to Outputs:
        + backend_internal_lb_ip = "10.0.10.100"
        + bucket_url             = (known after apply)
        + frontend_lb_ip         = (known after apply)
        + frontend_url           = (known after apply)
        + instance_group_app     = (known after apply)
        + instance_group_web     = (known after apply)
        + self_link_app          = (known after apply)
        + self_link_web          = (known after apply)

13. Agora iniciaremos a implementação com o comando: terraform apply
14. Quando solicitado, digite "yes" para continuar. Agora só aguardar. Leva aproximadamente uns 10min.
15. Para validar se todos os componentes foram criados corretamente, basta acessar seus respectivos menus no console.

## ⚙️ Pós Instalação

Agora precisamos habilitar o Security Command Center para o projeto escolhido.

Verifique se sua conta de usuário possue os papeis abaixo no projeto a ser utilizado:
    - "roles/securitycenter.admin"
    - "roles/iam.securityAdmin"

E as permissões abaixo no nível de organização se necessário:
    - securitycenter.assets.group
    - securitycenter.assets.list
    - securitycenter.findings.group
    - securitycenter.findings.list
    - securitycenter.sources.get
    - securitycenter.sources.list
    - securitycenter.userinterfacemetadata.get

1. Acesse a página Visão geral do Security Command Center no console do Google Cloud.
    https://console.cloud.google.com/projectselector2/security/command-center/welcome?supportedpurview=project

2. Selecione o nome do projeto para o qual você precisa ativar o Security Command Center.
    Após selecionar o projeto, uma das seguintes páginas será aberta:
    - Se o Security Command Center estiver ativo na sua organização, a página Visão geral de riscos será aberta.
    - Se o Security Command Center não tiver sido ativado na organização, a página Obter Security Command Center será aberta, a partir da qual você poderá iniciar o processo de ativação do seu projeto.
3. Se o Security Command Center já estiver ativo na sua organização, verifique o nível de serviço que está ativo no momento.
    a. Abra a página Configurações do Security Command Center: https://console.cloud.google.com/projectselector2/security/command-center/config/services?supportedpurview=project
    b. Na página Configurações, clique em Detalhes do Nível. A página Nível será aberta.
    c. Na linha Nível, o nível de serviço que o projeto está herdando é listado.
4. Para ativar o Security Command Center para um projeto, siga o procedimento para o estado de ativação do Security Command Center na organização pai:
    - Ativar para um projeto quando o Security Command Center estiver ativo na organização. (https://cloud.google.com/security-command-center/docs/activate-scc-for-a-project#project-activation-scc-active-in-org)
    - Ativar para um projeto quando o Security Command Center não estiver ativo na organização.  (https://cloud.google.com/security-command-center/docs/activate-scc-for-a-project#project-activation-scc-inactive-in-org)
    

## ✒️ Autores

Mencione todos aqueles que ajudaram a levantar o projeto desde o seu início

* **Jean Vinicius** - *IaC, Apresentação e  e Documentação* - [Cloud Architect - Pre-Sales | Tigabytes] (https://www.linkedin.com/in/jean-vf-pereira/)
* **Victor Souza** - *Apresentação* - [Cloud Architect - Pre-Sales | Tigabytes] (https://www.linkedin.com/in/victor-luis-in/)
* **Natanael Tavares** - *Arquitetura do Ambiente* - [Customer Engineer | Google] (https://www.linkedin.com/in/natanael-tavares-21ab18137/)
