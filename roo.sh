#!/bin/zsh

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configurações
WORKSPACE_DIR="$PWD"
CACHE_DIR="$HOME/.cache/roo-cli"
LOG_FILE="$HOME/.cache/roo-cli/roo.log"

# Cria diretórios necessários
mkdir -p "$CACHE_DIR"
touch "$LOG_FILE"

# Funções de log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Funções principais
edit_file() {
    local file=$1
    if [ -z "$file" ]; then
        printf "${YELLOW}Digite o nome do arquivo para editar: ${NC}"
        read file
    fi
    
    if [ ! -f "$file" ]; then
        printf "${BLUE}Criando novo arquivo: $file${NC}\n"
        touch "$file"
    fi
    
    printf "${BLUE}Editando $file...${NC}\n"
    printf "Digite o conteúdo (Ctrl+D para finalizar):\n"
    cat > "$file"
    printf "${GREEN}✓ Arquivo salvo!${NC}\n"
    log "Editado arquivo: $file"
}

run_code() {
    local file=$1
    if [ -z "$file" ]; then
        printf "${YELLOW}Digite o nome do arquivo para executar: ${NC}"
        read file
    fi
    
    if [ ! -f "$file" ]; then
        printf "${RED}Arquivo não encontrado!${NC}\n"
        return 1
    fi
    
    printf "${BLUE}Executando $file...${NC}\n"
    case "${file##*.}" in
        py) python3 "$file" ;;
        js) node "$file" ;;
        php) php "$file" ;;
        sh) zsh "$file" ;;
        *) printf "${RED}Extensão não suportada${NC}\n" ;;
    esac
    log "Executado arquivo: $file"
}

test_code() {
    local file=$1
    if [ -z "$file" ]; then
        printf "${YELLOW}Digite o nome do arquivo para testar: ${NC}"
        read file
    fi
    
    # Remove extensão para achar o arquivo de teste
    local base_name="${file%.*}"
    local test_file="test_${base_name}.py"
    
    if [ ! -f "$test_file" ]; then
        printf "${BLUE}Gerando testes para $file...${NC}\n"
        cat > "$test_file" << EOL
import pytest
from ${base_name} import *

def test_${base_name}_functionality():
    # Teste básico
    assert True
EOL
    fi
    
    printf "${BLUE}Executando testes...${NC}\n"
    pytest "$test_file" -v
    log "Testado arquivo: $file"
}

generate_docs() {
    local file=$1
    if [ -z "$file" ]; then
        printf "${YELLOW}Digite o nome do arquivo para documentar: ${NC}"
        read file
    fi
    
    if [ ! -f "$file" ]; then
        printf "${RED}Arquivo não encontrado!${NC}\n"
        return 1
    fi
    
    local doc_file="${file%.*}_docs.md"
    printf "${BLUE}Gerando documentação para $file...${NC}\n"
    
    # Extrai docstrings e comentários
    case "${file##*.}" in
        py)
            echo "# Documentação de $(basename "$file")" > "$doc_file"
            echo "\n## Funções\n" >> "$doc_file"
            grep -E '^[[:space:]]*def[[:space:]]+.*:|^[[:space:]]*class[[:space:]]+.*:' "$file" | sed 's/^[[:space:]]*def[[:space:]]\+\|^[[:space:]]*class[[:space:]]\+/- /' >> "$doc_file"
            ;;
        php)
            echo "# Documentação de $(basename "$file")" > "$doc_file"
            echo "\n## Funções\n" >> "$doc_file"
            grep -E '^[[:space:]]*function[[:space:]]+.*{' "$file" | sed 's/^[[:space:]]*function[[:space:]]\+\|{$//' >> "$doc_file"
            ;;
        *)
            printf "${RED}Tipo de arquivo não suportado para documentação${NC}\n"
            return 1
            ;;
    esac
    
    printf "${GREEN}✓ Documentação gerada em $doc_file${NC}\n"
    log "Gerada documentação para: $file"
}

analyze_code() {
    local file=$1
    if [ -z "$file" ]; then
        printf "${YELLOW}Digite o nome do arquivo para analisar: ${NC}"
        read file
    fi
    
    if [ ! -f "$file" ]; then
        printf "${RED}Arquivo não encontrado!${NC}\n"
        return 1
    fi
    
    printf "${BLUE}Analisando $file...${NC}\n"
    
    # Análise básica
    printf "\n${YELLOW}=== Estatísticas ===${NC}\n"
    printf "Linhas totais: $(wc -l < "$file")\n"
    printf "Linhas de código: $(grep -v '^[[:space:]]*$' "$file" | wc -l)\n"
    printf "Funções/Classes: $(grep -E '^[[:space:]]*(def|class|function)' "$file" | wc -l)\n"
    
    # Verifica problemas comuns
    printf "\n${YELLOW}=== Verificações ===${NC}\n"
    
    # Procura por TODOs
    todos=$(grep -n "TODO" "$file")
    if [ -n "$todos" ]; then
        printf "${YELLOW}TODOs encontrados:${NC}\n$todos\n"
    fi
    
    # Verifica imports não utilizados (Python)
    if [[ "$file" == *.py ]]; then
        printf "\n${YELLOW}=== Imports não utilizados ===${NC}\n"
        python3 -m pyflakes "$file" 2>/dev/null || printf "Instale pyflakes para verificar imports\n"
    fi
    
    log "Analisado arquivo: $file"
}

git_integration() {
    local action=$1
    local message=$2
    
    case $action in
        "status")
            git status
            ;;
        "add")
            if [ -z "$message" ]; then
                git add .
                printf "${GREEN}✓ Arquivos adicionados ao stage${NC}\n"
            else
                git add "$message"
                printf "${GREEN}✓ Arquivo $message adicionado ao stage${NC}\n"
            fi
            ;;
        "commit")
            if [ -z "$message" ]; then
                printf "${YELLOW}Digite a mensagem do commit: ${NC}"
                read message
            fi
            git commit -m "$message"
            printf "${GREEN}✓ Commit realizado${NC}\n"
            ;;
        "push")
            git push
            printf "${GREEN}✓ Push realizado${NC}\n"
            ;;
        *)
            printf "${RED}Ação git inválida${NC}\n"
            return 1
            ;;
    esac
    
    log "Executada ação git: $action"
}

# Menu de ajuda
show_help() {
    printf "${BLUE}=== Roo CLI - Comandos ===${NC}\n"
    printf "edit [arquivo]     - Edita ou cria um arquivo\n"
    printf "run [arquivo]      - Executa um arquivo\n"
    printf "test [arquivo]     - Executa/gera testes\n"
    printf "doc [arquivo]      - Gera documentação\n"
    printf "analyze [arquivo]  - Analisa código\n"
    printf "git [ação] [args]  - Integração com git\n"
    printf "help              - Mostra esta ajuda\n"
    printf "exit              - Sai do Roo CLI\n"
}

# Loop principal
printf "${GREEN}Roo CLI iniciado. Digite 'help' para ver os comandos.${NC}\n"

while true; do
    printf "${BLUE}roo>${NC} "
    read -r cmd file args
    
    case $cmd in
        "edit") edit_file "$file" ;;
        "run") run_code "$file" ;;
        "test") test_code "$file" ;;
        "doc") generate_docs "$file" ;;
        "analyze") analyze_code "$file" ;;
        "git") git_integration "$file" "$args" ;;
        "help") show_help ;;
        "exit") break ;;
        *) 
            if [ -n "$cmd" ]; then
                printf "${RED}Comando inválido. Digite 'help' para ver os comandos.${NC}\n"
            fi
            ;;
    esac
done

printf "${GREEN}Roo CLI finalizado.${NC}\n" 