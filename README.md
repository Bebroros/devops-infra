# Як користуватися
1. Ініціалізація: ```terraform init```
2. Встановити та налаштувати AWS: ```aws configure```
3. Створити файл terraform.tfvars та заповнити інформацією:<br>
1)```cloudflare_api_token  = "API_TOKEN"```<br>
2)```aws_ssh_keys_location = "relative/path/to/ssh/keys"```
4. Створення інфраструктури: ```terraform apply```
5. Знищення інфраструктури: ```terraform destroy```
