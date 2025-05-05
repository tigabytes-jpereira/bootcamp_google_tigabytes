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
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Retail Rocket</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; background-color: #f4f4f4; color: #333; }
        .header { background-color: #ff6600; padding: 20px; color: white; font-size: 24px; }
        .product-container { display: flex; flex-wrap: wrap; justify-content: center; gap: 20px; padding: 20px; }
        .product { background: white; padding: 15px; border-radius: 10px; box-shadow: 2px 2px 10px rgba(0,0,0,0.1); width: 200px; }
        .cart { margin-top: 20px; background: white; padding: 15px; border-radius: 10px; box-shadow: 2px 2px 10px rgba(0,0,0,0.1); width: 50%; margin: auto; }
        button { background-color: #ff6600; color: white; border: none; padding: 10px; cursor: pointer; border-radius: 5px; }
        button:hover { background-color: #e65c00; }
    </style>
</head>
<body>
    <div class="header">Retail Rocket - Instance utilizada: $vm_hostname</div>
    <div class="product-container">
        <!-- Produtos inseridos manualmente -->
        <div class="product">
            <strong>Notebook Dell XPS 15</strong><br>
            <span>USD 7500.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Smartphone Samsung S23</strong><br>
            <span>USD 4500.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Teclado Mecânico RGB</strong><br>
            <span>USD 350.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Mouse Logitech MX Master</strong><br>
            <span>USD 499.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Monitor LG Ultrawide</strong><br>
            <span>USD 1800.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Fone de Ouvido JBL Tune</strong><br>
            <span>USD 599.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>SSD NVMe 1TB Samsung</strong><br>
            <span>USD 799.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Cadeira Gamer DT3</strong><br>
            <span>USD 1200.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Impressora HP Deskjet</strong><br>
            <span>USD 450.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Webcam Logitech C920</strong><br>
            <span>USD 550.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Placa de Vídeo RTX 4070</strong><br>
            <span>USD 4500.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Memória RAM 32GB DDR4</strong><br>
            <span>USD 900.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>HD Externo 2TB Seagate</strong><br>
            <span>USD 500.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Roteador Wi-Fi 6 TP-Link</strong><br>
            <span>USD 650.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Apple Watch Series 9</strong><br>
            <span>USD 3200.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Kindle Paperwhite</strong><br>
            <span>USD 750.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Echo Dot 5ª Geração</strong><br>
            <span>USD 350.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Caixa de Som JBL Flip 6</strong><br>
            <span>USD 799.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Câmera GoPro Hero 11</strong><br>
            <span>USD 2500.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
        <div class="product">
            <strong>Microfone Blue Yeti</strong><br>
            <span>USD 899.00</span><br>
            <button>Adicionar ao Carrinho</button>
        </div>
    </div>
    <div class="cart">
        <h2>Carrinho</h2>
        <ul id="cart-list"></ul>
        <button>Finalizar Compra</button>
    </div>
</body>
</html>
EOF

echo "Configuração concluída! O site está rodando no servidor Nginx."
