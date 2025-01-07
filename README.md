<p align="center">
  <img src="https://i.ibb.co/zs1zcs3/Video-Frame.png" width="30%" />
</p>


# infra-api-gateway-video-frame-pro-api

Este repositório é responsável pela configuração do **API Gateway** para expor as APIs de autenticação, upload de vídeos e consulta de status. Ele também integra com o **Cognito** para autenticação via JWT.

## Funções
- Criar e configurar o **API Gateway** com as rotas necessárias.
- Integrar o **API Gateway** com o **Cognito** para proteger as APIs com autenticação JWT.
- Expor os endpoints de upload de vídeos e consulta de status.

## Tecnologias
- AWS API Gateway
- AWS Cognito (Autenticação via JWT)

## Como usar
1. Configure o ambiente com as credenciais do Cognito.
2. Execute os scripts para provisionar as APIs no API Gateway.
3. Defina as rotas: `/auth/register`, `/auth/login`, `/upload`, `/status/{videoId}`.
