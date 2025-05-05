#!/bin/bash

# Atualiza os pacotes do sistema
sudo apt update -y && sudo apt upgrade -y

# Instala o servidor Nginx
sudo apt install -y nginx

# Habilita e inicia o serviço Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

#Coleta o hostname da instância em uso
vm_hostname=\"$(curl \"http://metadata.google.internal/computeMetadata/v1/instance/name\" -H \"Metadata-Flavor:Google\")

# Cria o arquivo index.html com o conteúdo do site
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="pt-BR">
<body>
    Bienvenido a Tigabytes! Instance utilizada: $vm_hostname da subnet privada.
</body>
</html>
EOF

echo "Configuração concluída! O site está rodando no servidor Nginx."
