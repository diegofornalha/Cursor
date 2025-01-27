#!/bin/zsh

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Diretórios
ROO_DIR="$HOME/.roo-cline"
CONFIG_FILE="$ROO_DIR/config.json"

# Cria diretórios necessários
setup_directories() {
    printf "${BLUE}Configurando Roo-Cline...${NC}\n"
    mkdir -p "$ROO_DIR"
    mkdir -p "$ROO_DIR/cache"
    mkdir -p "$ROO_DIR/logs"
}

# Instala dependências
install_dependencies() {
    printf "${BLUE}Instalando dependências...${NC}\n"
    
    # Verifica se Homebrew está instalado
    if ! command -v brew &> /dev/null; then
        printf "${YELLOW}Instalando Homebrew...${NC}\n"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Instala dependências via Homebrew
    brew install jq
    brew install python@3.11
    
    # Instala dependências Python
    pip3 install --user roo-cline
}

# Configura o Roo-Cline
configure_roo() {
    printf "${BLUE}Configurando Roo-Cline...${NC}\n"
    
    # Cria arquivo de configuração
    cat > "$CONFIG_FILE" << EOL
{
    "model": "deepseek-chat",
    "context_length": 2048,
    "cache_enabled": true,
    "cache_dir": "$ROO_DIR/cache",
    "log_dir": "$ROO_DIR/logs",
    "language": "pt-BR",
    "features": {
        "auto_complete": true,
        "syntax_highlight": true,
        "inline_docs": true,
        "smart_indent": true
    },
    "performance": {
        "max_tokens": 2048,
        "request_timeout": 30,
        "cache_ttl": 3600
    }
}
EOL
}

# Configura aliases úteis
setup_aliases() {
    printf "${BLUE}Configurando aliases...${NC}\n"
    
    # Adiciona aliases ao .zshrc
    cat >> "$HOME/.zshrc" << EOL

# Aliases Roo-Cline
alias roo='roo-cline'
alias roo-edit='roo edit'
alias roo-run='roo run'
alias roo-test='roo test'
alias roo-doc='roo doc'
EOL

    source "$HOME/.zshrc"
}

# Menu principal
show_menu() {
    printf "${BLUE}=== Instalador Roo-Cline ===${NC}\n"
    printf "1. Instalar Roo-Cline\n"
    printf "2. Configurar ambiente\n"
    printf "3. Configurar aliases\n"
    printf "4. Instalar tudo\n"
    printf "q. Sair\n"
    printf "${BLUE}=====================${NC}\n"
}

# Loop principal
while true; do
    show_menu
    printf "Escolha uma opção: "
    read choice
    
    case $choice in
        1) 
            setup_directories
            install_dependencies
            printf "${GREEN}✓ Roo-Cline instalado!${NC}\n"
            ;;
        2)
            configure_roo
            printf "${GREEN}✓ Ambiente configurado!${NC}\n"
            ;;
        3)
            setup_aliases
            printf "${GREEN}✓ Aliases configurados!${NC}\n"
            ;;
        4)
            setup_directories
            install_dependencies
            configure_roo
            setup_aliases
            printf "${GREEN}✓ Instalação completa finalizada!${NC}\n"
            printf "${YELLOW}Para começar, abra um novo terminal e digite 'roo'${NC}\n"
            ;;
        q) exit 0 ;;
        *) printf "${RED}Opção inválida${NC}\n" ;;
    esac
    
    printf "\nPressione ENTER para continuar..."
    read
    clear
done 