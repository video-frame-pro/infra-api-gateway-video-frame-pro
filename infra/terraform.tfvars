######### PREFIXO DO PROJETO ###########################################
prefix_name = "video-frame-pro"

######### AWS CONFIGURATION ###########################################
aws_region = "us-east-1" # Região AWS onde os recursos serão provisionados
stage_name = "prod"      # Nome do estágio do API Gateway

######### LAMBDAS INFOS ##########################################
lambda_register_name     = "register"
lambda_login_name        = "login"
lambda_orchestrator_name = "orchestrator"
lambda_status_name       = "status"

######### COGNITO #####################################################
cognito_user_pool_id_ssm = "/video-frame-pro/cognito/user_pool_id"

######### LOGS CLOUD WATCH #############################################
log_retention_days = 7 # Dias para retenção dos logs no CloudWatch
