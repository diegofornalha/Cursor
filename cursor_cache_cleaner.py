import os
import shutil
from datetime import datetime
import logging
from pathlib import Path
import psutil
import signal
import sys

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

def is_cursor_running():
    """Verifica se o Cursor está em execução"""
    for proc in psutil.process_iter(['name']):
        try:
            if 'cursor' in proc.info['name'].lower():
                return True
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass
    return False

def get_dir_size(path):
    """Calcula o tamanho total de um diretório"""
    total = 0
    with os.scandir(path) as it:
        for entry in it:
            if entry.is_file():
                total += entry.stat().st_size
            elif entry.is_dir():
                total += get_dir_size(entry.path)
    return total

def clean_cache():
    """Limpa os diretórios de cache do Cursor"""
    if is_cursor_running():
        logging.warning("Cursor está em execução. Recomendado fechar antes da limpeza.")
        return

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

    total_size_before = get_dir_size(cursor_path)

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

    total_size_after = get_dir_size(cursor_path)
    space_saved = (total_size_before - total_size_after) / (1024 * 1024)  # MB
    logging.info(f"Espaço economizado: {space_saved:.2f} MB")

def rotate_log_file(max_size_mb=10):
    """Rotaciona o arquivo de log se exceder o tamanho máximo"""
    log_file = 'cursor_cache_cleaner.log'
    try:
        if os.path.exists(log_file) and os.path.getsize(log_file) > max_size_mb * 1024 * 1024:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            os.rename(log_file, f'{log_file}.{timestamp}')
    except Exception as e:
        print(f"Erro ao rotacionar log: {e}")

def signal_handler(signum, frame):
    """Trata interrupções do sistema"""
    logging.warning("Operação interrompida pelo usuário")
    sys.exit(1)

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

if __name__ == "__main__":
    rotate_log_file()
    clean_cache() 