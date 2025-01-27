import os
import shutil
from datetime import datetime
import logging
from pathlib import Path

# Configurar logging
logging.basicConfig(
    filename='cursor_cache_cleaner.log',
    level=logging.INFO,
    format='%(asctime)s - %(message)s'
)

def get_cursor_cache_path():
    """Retorna o caminho para o diretório de cache do Cursor baseado no sistema operacional"""
    home = Path.home()
    
    if os.name == 'nt':  # Windows
        return home / 'AppData/Local/Cursor'
    else:  # macOS e Linux
        return home / 'Library/Application Support/Cursor'

def clean_cache():
    """Limpa os diretórios de cache do Cursor"""
    cache_dirs = [
        'Cache_Data',
        'CachedData',
        'CachedExtensionVSIXs',
        'CachedProfilesData',
        'Code Cache',
        'DawnGraphiteCache',
        'DawnWebGPUCache',
        'GPUCache',
        'Local Storage',
        'Session Storage',
        'Shared Dictionary',
    ]

    cursor_path = get_cursor_cache_path()
    
    if not cursor_path.exists():
        logging.error(f"Diretório do Cursor não encontrado em: {cursor_path}")
        return

    cleaned = 0
    errors = 0
    
    for cache_dir in cache_dirs:
        cache_path = cursor_path / cache_dir
        if cache_path.exists():
            try:
                if cache_path.is_dir():
                    shutil.rmtree(cache_path)
                else:
                    os.remove(cache_path)
                cleaned += 1
                logging.info(f"Limpou: {cache_dir}")
            except Exception as e:
                errors += 1
                logging.error(f"Erro ao limpar {cache_dir}: {str(e)}")

    # Registrar resumo
    logging.info(f"Limpeza concluída: {cleaned} diretórios limpos, {errors} erros")
    
    # Criar diretórios vazios novamente
    for cache_dir in cache_dirs:
        cache_path = cursor_path / cache_dir
        if not cache_path.exists():
            try:
                os.makedirs(cache_path)
            except Exception as e:
                logging.error(f"Erro ao recriar diretório {cache_dir}: {str(e)}")

if __name__ == "__main__":
    clean_cache() 