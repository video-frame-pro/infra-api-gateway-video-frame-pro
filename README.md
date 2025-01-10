<p align="center">
  <img src="https://i.ibb.co/zs1zcs3/Video-Frame.png" width="30%" />
</p>

# infra-api-gateway-video-frame-pro-api

Este repositório é responsável pela configuração do **API Gateway** para expor as APIs de autenticação, upload de vídeos e consulta de status. Ele também integra com o **Cognito** para autenticação via JWT e funções Lambda para o processo de login e registro de usuários.

## Funções
- Criar e configurar o **API Gateway** com as rotas necessárias para registro de usuários, login, upload de vídeos e consulta de status.
- Integrar o **API Gateway** com o **Cognito User Pool** para autenticação via JWT.
- Expor os endpoints de **/auth/register** para registro de usuário, **/auth/login** para login, **/upload** para envio de vídeos, e **/status/{videoId}** para consulta de status do upload.
- A integração com **AWS Lambda** para as funções de **registro de usuário** e **login**.

## Tecnologias

Aqui estão as principais tecnologias usadas neste repositório:

<p>
  <img src="https://img.shields.io/badge/AWS-232F3E?logo=amazonaws&logoColor=white" alt="AWS" />
  <img src="https://img.shields.io/badge/AWS_Lambda-4B5A2F?logo=aws-lambda&logoColor=white" alt="AWS Lambda" />
  <img src="https://img.shields.io/badge/AWS_Cognito-FF9900?logo=aws-cognito&logoColor=white" alt="AWS Cognito" />
  <img src="https://img.shields.io/badge/API_Gateway-0052CC?logo=amazon-api-gateway&logoColor=white" alt="API Gateway" />
  <img src="https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white" alt="Python" />
  <img src="https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white" alt="Terraform" />
</p>

## Como usar

### Pré-requisitos
1. **Credenciais AWS**: Certifique-se de que você tenha as credenciais da AWS configuradas corretamente em seu ambiente. Isso pode ser feito utilizando o AWS CLI ou variáveis de ambiente.
2. **Terraform**: Instale o Terraform em sua máquina para poder aplicar a infraestrutura.

### Passos

1. **Configurar as variáveis**
    - No arquivo `terraform.tfvars`, adicione os valores corretos para o Cognito User Pool, ARNs das funções Lambda de registro e login, e região da AWS:
      ```hcl
      cognito_user_pool_id = "us-east-1_ExemploIDPool"  # Substitua pelo seu User Pool ID
      cognito_user_pool_arn = "arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_ExemploIDPool"  # Substitua pelo seu ARN do User Pool
      auth_register_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:auth-register-example"  # Substitua pelo ARN da Lambda de registro
      auth_login_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:auth-login-example"  # Substitua pelo ARN da Lambda de login
      aws_region = "us-east-1"  # Região AWS em que os recursos estão sendo provisionados
      ```

2. **Provisionar a infraestrutura**
    - Execute os seguintes comandos para inicializar o Terraform e aplicar a configuração:
      ```bash
      terraform init
      terraform apply
      ```

3. **Testar os Endpoints**
    - Após o Terraform aplicar a infraestrutura, o API Gateway estará disponível. Os endpoints que você pode acessar são:
        - **POST /auth/register**: Endpoint para registrar um novo usuário (com nome de usuário, senha e e-mail).
        - **POST /auth/login**: Endpoint para autenticação do usuário, recebendo o nome de usuário e senha.
        - **POST /upload**: Endpoint para enviar arquivos de vídeo.
        - **GET /status/{videoId}**: Endpoint para consultar o status do upload do vídeo.

4. **Autenticação**
    - O endpoint de **login (/auth/login)** utiliza o **Cognito User Pool** para autenticação via JWT. Após o login, o usuário receberá um token de autenticação que será utilizado para acessar os endpoints protegidos do API Gateway.

5. **Configuração do API Gateway**
    - A infraestrutura cria automaticamente o API Gateway com as rotas de `/auth/register`, `/auth/login`, `/upload`, e `/status/{videoId}`.
    - O **authorizer do Cognito** é configurado para proteger os endpoints com autenticação JWT.

### Como funciona
1. **Registro de Usuário (`/auth/register`)**:
    - O usuário pode se registrar fornecendo um nome de usuário, senha e email.
    - O **API Gateway** invoca a função **Lambda** de registro, que usa o Cognito para registrar o novo usuário.

2. **Login de Usuário (`/auth/login`)**:
    - O usuário pode se autenticar fornecendo um nome de usuário e senha.
    - O **API Gateway** invoca a função **Lambda** de login, que usa o Cognito para autenticar e retornar o **JWT**.

3. **Upload de Vídeos (`/upload`)**:
    - A API do **upload** está disponível para receber arquivos de vídeo (este endpoint precisa ser configurado para aceitar uploads de arquivos conforme necessário).

4. **Consulta de Status (`/status/{videoId}`)**:
    - Este endpoint permite consultar o status do vídeo (por exemplo, se o upload foi concluído, etc.).

---

## Conclusão
Este repositório proporciona uma configuração completa do **API Gateway** integrado com **AWS Cognito** para autenticação via JWT, permitindo que usuários se registrem e façam login para acessar APIs protegidas. A infraestrutura é gerenciada com **Terraform**, proporcionando escalabilidade e reusabilidade.

---
