#!/bin/zsh

# Configuração do Deepseek para o terminal
export DEEPSEEK_API_KEY="sk-a31cf6daee5d42418c6b61a80ea8a0e9"
export DEEPSEEK_MODEL="deepseek-coder"
export DEEPSEEK_CONTEXT_LENGTH=128000

# Aliases úteis
alias dc="deepseek-cli"
alias drun="deepseek-cli run"
alias dhelp="deepseek-cli help"

# Mensagem de inicialização
echo "Terminal configurado com Deepseek Coder"
echo "Use 'dc' para comandos Deepseek" 