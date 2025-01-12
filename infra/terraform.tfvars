# terraform.tfvars
aws_region = "us-east-1"

cognito_user_pool_id = "us-east-1_ZL87UW5Jl"
cognito_user_pool_arn = "arn:aws:cognito-idp:us-east-1:522814708374:userpool/us-east-1_ZL87UW5Jl"

auth_register_lambda_name = "user_register_function"
auth_login_lambda_name = "user_login_function"

auth_register_lambda_arn = "arn:aws:lambda:us-east-1:522814708374:function:user_register_function"
auth_login_lambda_arn = "arn:aws:lambda:us-east-1:522814708374:function:user_login_function"

