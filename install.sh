#!/bin/bash

# SSH Bot Premium - Script de Instalação
# Instala e configura o bot SSH com sistema de vendas

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    SSH Bot Premium v2.0                     ║"
echo "║              Sistema Completo de Vendas SSH                 ║"
echo "║                                                              ║"
echo "║  • Pagamentos automáticos via PIX (Mercado Pago)           ║"
echo "║  • Sistema de notificações em tempo real                    ║"
echo "║  • Painel administrativo completo                           ║"
echo "║  • Configuração via chat do bot                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verifica se está rodando como root
if [[ $EUID -ne 0 ]]; then
   print_error "Este script deve ser executado como root!"
   exit 1
fi

# Verifica sistema operacional
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    print_error "Este script é compatível apenas com Linux!"
    exit 1
fi

print_status "Iniciando instalação do SSH Bot Premium..."

# Atualiza sistema
print_status "Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

# Instala dependências do sistema
print_status "Instalando dependências do sistema..."
sudo apt install -y python3 python3-pip python3-venv git curl wget unzip

# Verifica se Python 3.8+ está disponível
python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
required_version="3.8"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then
    print_error "Python 3.8+ é necessário. Versão atual: $python_version"
    exit 1
fi

print_success "Python $python_version detectado"

# Cria diretório do projeto
PROJECT_DIR="$HOME/ssh-bot-premium"
print_status "Criando diretório do projeto: $PROJECT_DIR"

if [ -d "$PROJECT_DIR" ]; then
    print_warning "Diretório já existe. Fazendo backup..."
    mv "$PROJECT_DIR" "$PROJECT_DIR.backup.$(date +%Y%m%d_%H%M%S)"
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Cria ambiente virtual
print_status "Criando ambiente virtual Python..."
python3 -m venv venv
source venv/bin/activate

# Atualiza pip
print_status "Atualizando pip..."
pip install --upgrade pip

# Instala dependências Python
print_status "Instalando dependências Python..."
cat > requirements.txt << EOF
python-telegram-bot==20.7
requests==2.31.0
mercadopago==2.2.1
python-dotenv==1.0.0
flask==2.3.3
flask-cors==4.0.0
aiohttp==3.8.6
asyncio
sqlite3
EOF

pip install -r requirements.txt

print_success "Dependências Python instaladas"

# Cria estrutura de arquivos
print_status "Criando estrutura do projeto..."

# Cria arquivo de configuração padrão
cat > config.json << EOF
{
  "bot_token": "SEU_TOKEN_DO_BOT_AQUI",
  "mercado_pago_access_token": "SEU_ACCESS_TOKEN_MP_AQUI",
  "admin_ids": [123456789],
  "notification_group_id": -1001234567890,
  "webhook_url": "https://seu-dominio.com",
  "ssh_servers": [
    {
      "name": "Servidor Principal",
      "ip": "SEU-IP-AQUI",
      "password": "SUA-SENHA-AQUI",
      "port": 22,
      "active": true
    }
  ],
  "pricing": {
    "weekly": {
      "price": 10.00,
      "duration_days": 7,
      "description": "Plano Semanal"
    },
    "monthly": {
      "price": 20.00,
      "duration_days": 30,
      "description": "Plano Mensal"
    }
  },
  "messages": {
    "welcome": "🌟 Bem-vindo ao SSH Bot Premium!",
    "test_limit": "❌ Você já criou um teste nas últimas 24 horas.",
    "server_error": "❌ Erro temporário. Tente novamente em alguns minutos."
  }
}
EOF

# Cria arquivo .env
cat > .env << EOF
# Configurações do Bot SSH Premium
BOT_TOKEN=SEU_TOKEN_DO_BOT_AQUI
MERCADO_PAGO_ACCESS_TOKEN=SEU_ACCESS_TOKEN_MP_AQUI
WEBHOOK_URL=https://seu-dominio.com
DATABASE_PATH=bot_database.db
LOG_LEVEL=INFO
EOF

# Cria script de inicialização
cat > start.sh << 'EOF'
#!/bin/bash

# Script de inicialização do SSH Bot Premium

cd "$(dirname "$0")"

# Ativa ambiente virtual
source venv/bin/activate

# Verifica se config.json existe e está configurado
if [ ! -f "config.json" ]; then
    echo "❌ Arquivo config.json não encontrado!"
    exit 1
fi

# Verifica se token está configurado
if grep -q "SEU_TOKEN_DO_BOT_AQUI" config.json; then
    echo "❌ Configure o token do bot em config.json primeiro!"
    echo "💡 Use: python3 setup.py para configuração interativa"
    exit 1
fi

echo "🚀 Iniciando SSH Bot Premium..."
python3 main_bot.py
EOF

chmod +x start.sh

# Cria script de configuração interativa
cat > setup.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de configuração interativa do SSH Bot Premium
"""

import json
import os
import sys

def print_banner():
    print("\n" + "="*60)
    print("           SSH Bot Premium - Configuração")
    print("="*60)

def load_config():
    try:
        with open('config.json', 'r') as f:
            return json.load(f)
    except:
        return {}

def save_config(config):
    with open('config.json', 'w') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)

def get_input(prompt, current_value=None, required=True):
    if current_value and current_value != "SEU_TOKEN_DO_BOT_AQUI":
        prompt += f" (atual: {current_value[:20]}...)"
    
    prompt += ": "
    value = input(prompt).strip()
    
    if not value and current_value:
        return current_value
    
    if required and not value:
        print("❌ Este campo é obrigatório!")
        return get_input(prompt, current_value, required)
    
    return value

def main():
    print_banner()
    
    config = load_config()
    
    print("\n📋 Configuração Básica:")
    print("-" * 30)
    
    # Token do bot
    config['bot_token'] = get_input(
        "🤖 Token do Bot Telegram",
        config.get('bot_token')
    )
    
    # Token Mercado Pago
    config['mercado_pago_access_token'] = get_input(
        "💳 Access Token Mercado Pago",
        config.get('mercado_pago_access_token')
    )
    
    # Admin ID
    admin_input = get_input(
        "👤 Seu ID do Telegram (admin)",
        str(config.get('admin_ids', [0])[0]) if config.get('admin_ids') else None
    )
    
    try:
        config['admin_ids'] = [int(admin_input)]
    except:
        print("❌ ID inválido!")
        return
    
    # Webhook URL
    config['webhook_url'] = get_input(
        "🌐 URL do Webhook (opcional)",
        config.get('webhook_url', ''),
        required=False
    )
    
    print("\n🖥️ Configuração de Servidor SSH:")
    print("-" * 35)
    
    if 'ssh_servers' not in config:
        config['ssh_servers'] = []
    
    # Servidor SSH
    server_name = get_input("📝 Nome do Servidor", "Servidor Principal")
    server_ip = get_input("🌐 IP do Servidor")
    server_password = get_input("🔑 Senha do Servidor")
    
    config['ssh_servers'] = [{
        "name": server_name,
        "ip": server_ip,
        "password": server_password,
        "port": 22,
        "active": True
    }]
    
    print("\n💰 Configuração de Preços:")
    print("-" * 25)
    
    try:
        weekly_price = float(get_input("💎 Preço Semanal (R$)", "10.00"))
        monthly_price = float(get_input("🔥 Preço Mensal (R$)", "20.00"))
        
        config['pricing'] = {
            "weekly": {
                "price": weekly_price,
                "duration_days": 7,
                "description": "Plano Semanal"
            },
            "monthly": {
                "price": monthly_price,
                "duration_days": 30,
                "description": "Plano Mensal"
            }
        }
    except:
        print("❌ Preços inválidos!")
        return
    
        # Desativar Bot
    config["bot_active"] = get_input(
        "🟢 Ativar bot? (true/false)",
        str(config.get("bot_active", True))
    ).lower() == "true"

    # Salva configuração
    save_config(config)

if __name__ == "__main__":
    main()
EOF

chmod +x setup.py

# Cria script de atualização
    # Cria script de atualização
cat > update.sh << 'EOF'
#!/bin/bash

# Script de atualização do SSH Bot Premium

REPO_URL="https://github.com/seu-usuario/seu-repositorio-bot.git" # Substitua pelo seu repositório
PROJECT_DIR="$(dirname "$0")"

echo "🔄 Verificando atualizações para SSH Bot Premium..."

cd "$PROJECT_DIR"

# Ativa ambiente virtual
source venv/bin/activate

# Puxa as últimas mudanças do repositório
if git pull $REPO_URL main; then
    echo "✅ Código atualizado com sucesso!"
else
    echo "❌ Erro ao puxar atualizações do repositório. Verifique sua conexão ou URL do repositório."
    exit 1
fi

# Atualiza dependências
pip install --upgrade -r requirements.txt

echo "✅ Atualização de dependências concluída!"

echo "🔄 Reiniciando o bot..."
# Para o bot se estiver rodando (assumindo que o bot é iniciado com start.sh e pode ser parado)
# Isso é um placeholder, a forma correta de parar e reiniciar um bot em produção depende de como ele é gerenciado (systemd, pm2, etc.)
# Por simplicidade, vamos apenas tentar reiniciar o script principal.

# Verifica se o bot está rodando e tenta pará-lo
# PIDs=$(pgrep -f "python3 main_bot.py")
# if [ -n "$PIDs" ]; then
#     echo "Parando processos do bot: $PIDs"
#     kill $PIDs
#     sleep 5 # Dá um tempo para o processo terminar
# fi

# Inicia o bot novamente
./start.sh

echo "✅ Bot reiniciado com sucesso!"

echo "✅ Atualização concluída!"
EOF

chmod +x update.sh

# Cria serviço systemd (opcional)
cat > ssh-bot-premium.service << EOF
[Unit]
Description=SSH Bot Premium
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/venv/bin/python $PROJECT_DIR/main_bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

print_success "Estrutura do projeto criada"

# Cria README
cat > README.md << 'EOF'
# SSH Bot Premium v2.0

Sistema completo de vendas SSH com pagamentos automáticos via PIX.

## 🚀 Características

- ✅ Pagamentos automáticos via PIX (Mercado Pago)
- ✅ Sistema de notificações em tempo real
- ✅ Painel administrativo completo
- ✅ Configuração via chat do bot
- ✅ Múltiplos servidores SSH
- ✅ Sistema de usuários premium
- ✅ Webhook para processamento automático

## 📋 Pré-requisitos

- Python 3.8+
- Token do Bot Telegram
- Access Token do Mercado Pago
- Servidor(es) SSH configurado(s)

## 🛠️ Instalação

1. Execute o script de instalação:
```bash
curl -sSL https://raw.githubusercontent.com/seu-repo/install.sh | bash
```

2. Configure o bot:
```bash
cd ~/ssh-bot-premium
python3 setup.py
```

3. Inicie o bot:
```bash
./start.sh
```

## ⚙️ Configuração

### Configuração Básica
Use o script interativo:
```bash
python3 setup.py
```

### Configuração Avançada
Use o comando `/config` no bot para acessar o painel administrativo.

### Webhook Mercado Pago
Configure no painel do MP:
- URL: `https://seu-dominio.com/webhook/mercadopago`
- Eventos: `payment`

## 📱 Comandos do Bot

### Usuários
- `/start` - Menu principal
- `/help` - Ajuda

### Administradores
- `/config` - Painel de configuração
- `/status` - Status do sistema
- `/stats` - Estatísticas
- `/setgroup` - Define grupo de notificações
- `/addadmin <id>` - Adiciona admin
- `/setmptoken <token>` - Define token MP

## 🔧 Manutenção

### Logs
```bash
tail -f bot.log
```

### Atualização
```bash
./update.sh
```

### Backup
```bash
cp config.json config.json.backup
cp bot_database.db bot_database.db.backup
```

## 🆘 Suporte

Para suporte técnico, entre em contato via Telegram: @proverbiox9

## 📄 Licença

Este projeto é proprietário. Todos os direitos reservados.
EOF

print_success "Documentação criada"

# Finalização
print_status "Criando atalhos..."

# Cria atalho no desktop (se existir)
if [ -d "$HOME/Desktop" ]; then
    cat > "$HOME/Desktop/SSH Bot Premium.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=SSH Bot Premium
Comment=Sistema de Vendas SSH
Exec=$PROJECT_DIR/start.sh
Icon=utilities-terminal
Terminal=true
Categories=Network;
EOF
    chmod +x "$HOME/Desktop/SSH Bot Premium.desktop"
fi

# Adiciona ao PATH (opcional)
if ! grep -q "ssh-bot-premium" "$HOME/.bashrc"; then
    echo "export PATH=\"$PROJECT_DIR:\$PATH\"" >> "$HOME/.bashrc"
fi

print_success "Instalação concluída!"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                     INSTALAÇÃO CONCLUÍDA!                   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📁 Projeto instalado em:${NC} $PROJECT_DIR"
echo ""
echo -e "${YELLOW}📋 PRÓXIMOS PASSOS:${NC}"
echo -e "${BLUE}1.${NC} cd $PROJECT_DIR"
echo -e "${BLUE}2.${NC} python3 setup.py  ${GREEN}# Configuração interativa${NC}"
echo -e "${BLUE}3.${NC} ./start.sh        ${GREEN}# Iniciar o bot${NC}"
echo ""
echo -e "${YELLOW}💡 DICAS IMPORTANTES:${NC}"
echo -e "${BLUE}•${NC} Configure o webhook no painel do Mercado Pago"
echo -e "${BLUE}•${NC} Use /config no bot para configurações avançadas"
echo -e "${BLUE}•${NC} Adicione o bot aos grupos de notificação"
echo -e "${BLUE}•${NC} Teste em ambiente sandbox antes da produção"
echo ""
echo -e "${GREEN}🎉 SSH Bot Premium v2.0 pronto para uso!${NC}"
echo ""
EOF

chmod +x install.sh

