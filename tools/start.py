#!/usr/bin/env python3
"""
Script de inicio para el Sistema de Puntuación de Idiomas - Tutorium
Facilita el desarrollo, testing y deployment del sistema.
"""

import sys
import os
import subprocess
import argparse
from pathlib import Path

# Colores para output en terminal
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_colored(message, color=Colors.WHITE):
    """Imprime mensaje con color."""
    print(f"{color}{message}{Colors.END}")

def print_header(title):
    """Imprime encabezado con formato."""
    print_colored("=" * 60, Colors.CYAN)
    print_colored(f"🎯 {title}", Colors.BOLD + Colors.CYAN)
    print_colored("=" * 60, Colors.CYAN)

def run_command(command, description, check_result=True):
    """Ejecuta un comando y muestra el resultado."""
    print_colored(f"📋 {description}...", Colors.YELLOW)
    print_colored(f"💻 Ejecutando: {command}", Colors.BLUE)
    
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            check=check_result
        )
        
        if result.returncode == 0:
            print_colored("✅ Éxito", Colors.GREEN)
            if result.stdout.strip():
                print(result.stdout.strip())
        else:
            print_colored("❌ Error", Colors.RED)
            if result.stderr.strip():
                print_colored(result.stderr.strip(), Colors.RED)
        
        return result.returncode == 0
        
    except subprocess.CalledProcessError as e:
        print_colored(f"❌ Error ejecutando comando: {e}", Colors.RED)
        return False
    except Exception as e:
        print_colored(f"❌ Error inesperado: {e}", Colors.RED)
        return False

def setup_environment():
    """Configura el entorno de desarrollo."""
    print_header("Configuración del Entorno")
    
    success = True
    
    # Verificar Python
    print_colored("🐍 Verificando versión de Python...", Colors.YELLOW)
    python_version = sys.version_info
    if python_version.major >= 3 and python_version.minor >= 8:
        print_colored(f"✅ Python {python_version.major}.{python_version.minor}.{python_version.micro}", Colors.GREEN)
    else:
        print_colored("❌ Se requiere Python 3.8 o superior", Colors.RED)
        success = False
    
    # Instalar dependencias
    if success:
        success &= run_command(
            "pip install -r requirements.txt",
            "Instalando dependencias de Python"
        )
    
    # Verificar estructura de directorios
    dirs_to_check = ['tools', 'js', 'css', 'assets', 'logs', 'uploads']
    for dir_name in dirs_to_check:
        dir_path = Path(dir_name)
        if not dir_path.exists():
            print_colored(f"📁 Creando directorio: {dir_name}", Colors.YELLOW)
            dir_path.mkdir(exist_ok=True)
    
    return success

def run_tests():
    """Ejecuta las pruebas del sistema."""
    print_header("Ejecutando Tests")
    
    # Tests de Python
    success = run_command(
        "python tools/test_language_system.py",
        "Ejecutando tests del sistema de puntuación"
    )
    
    # Linting
    if success:
        print_colored("🔍 Ejecutando análisis de código...", Colors.YELLOW)
        run_command(
            "flake8 tools/ --max-line-length=88",
            "Análisis de estilo con flake8",
            check_result=False
        )
    
    return success

def start_api_server():
    """Inicia el servidor de API."""
    print_header("Iniciando Servidor de API")
    
    print_colored("🚀 Iniciando API en http://127.0.0.1:5000", Colors.GREEN)
    print_colored("📋 Endpoints disponibles:", Colors.CYAN)
    print("   - POST /api/analyze-language")
    print("   - GET  /api/student-progress/<id>")
    print("   - POST /api/save-analysis")
    print("   - GET  /api/health")
    print("   - GET  /api/supported-languages")
    print()
    print_colored("🛑 Presiona Ctrl+C para detener el servidor", Colors.YELLOW)
    
    try:
        subprocess.run(["python", "tools/language_api.py"], check=True)
    except KeyboardInterrupt:
        print_colored("\n👋 Servidor detenido", Colors.YELLOW)
    except Exception as e:
        print_colored(f"❌ Error iniciando servidor: {e}", Colors.RED)

def run_development_mode():
    """Ejecuta modo de desarrollo completo."""
    print_header("Modo de Desarrollo")
    
    print_colored("🔧 Configurando entorno de desarrollo...", Colors.CYAN)
    
    if not setup_environment():
        print_colored("❌ Error en configuración. Abortando.", Colors.RED)
        return False
    
    print_colored("🧪 Ejecutando tests...", Colors.CYAN)
    if not run_tests():
        print_colored("⚠️  Algunos tests fallaron, pero continuando...", Colors.YELLOW)
    
    print_colored("🚀 Iniciando servidor de desarrollo...", Colors.CYAN)
    start_api_server()

def run_production_check():
    """Verifica que el sistema esté listo para producción."""
    print_header("Verificación de Producción")
    
    checks = [
        ("python tools/test_language_system.py", "Tests del sistema"),
        ("flake8 tools/ --max-line-length=88", "Calidad de código"),
    ]
    
    all_passed = True
    for command, description in checks:
        if not run_command(command, description, check_result=False):
            all_passed = False
    
    # Verificar variables de entorno para producción
    required_env_vars = ['SECRET_KEY', 'DATABASE_URL']
    print_colored("🔐 Verificando variables de entorno...", Colors.YELLOW)
    
    for var in required_env_vars:
        if os.getenv(var):
            print_colored(f"✅ {var} configurada", Colors.GREEN)
        else:
            print_colored(f"⚠️  {var} no configurada", Colors.YELLOW)
            all_passed = False
    
    if all_passed:
        print_colored("🎉 ¡Sistema listo para producción!", Colors.GREEN)
    else:
        print_colored("⚠️  Hay problemas que resolver antes de producción", Colors.YELLOW)
    
    return all_passed

def show_system_info():
    """Muestra información del sistema."""
    print_header("Información del Sistema")
    
    # Información de Python
    print_colored("🐍 Python:", Colors.CYAN)
    print(f"   Versión: {sys.version}")
    print(f"   Ejecutable: {sys.executable}")
    
    # Información del proyecto
    print_colored("\n📁 Proyecto:", Colors.CYAN)
    print(f"   Directorio: {os.getcwd()}")
    
    # Archivos principales
    main_files = [
        'tools/language_scoring_system.py',
        'tools/language_api.py',
        'tools/config.py',
        'js/language_scorer.js',
        'requirements.txt'
    ]
    
    print_colored("\n📄 Archivos principales:", Colors.CYAN)
    for file_path in main_files:
        if os.path.exists(file_path):
            size = os.path.getsize(file_path)
            print_colored(f"   ✅ {file_path} ({size} bytes)", Colors.GREEN)
        else:
            print_colored(f"   ❌ {file_path} (no encontrado)", Colors.RED)

def main():
    """Función principal."""
    parser = argparse.ArgumentParser(
        description="Sistema de Puntuación de Idiomas - Tutorium",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  python start.py setup           # Configurar entorno
  python start.py test            # Ejecutar tests
  python start.py serve           # Iniciar servidor API
  python start.py dev             # Modo desarrollo completo
  python start.py check           # Verificar para producción
  python start.py info            # Mostrar información del sistema
        """
    )
    
    parser.add_argument(
        'command',
        choices=['setup', 'test', 'serve', 'dev', 'check', 'info'],
        help='Comando a ejecutar'
    )
    
    args = parser.parse_args()
    
    # Banner de bienvenida
    print_colored("🎓 Sistema de Puntuación de Idiomas - Tutorium", Colors.BOLD + Colors.MAGENTA)
    print_colored("   Análisis inteligente de idiomas con IA", Colors.MAGENTA)
    print()
    
    # Ejecutar comando
    try:
        if args.command == 'setup':
            setup_environment()
        elif args.command == 'test':
            run_tests()
        elif args.command == 'serve':
            start_api_server()
        elif args.command == 'dev':
            run_development_mode()
        elif args.command == 'check':
            run_production_check()
        elif args.command == 'info':
            show_system_info()
        
    except KeyboardInterrupt:
        print_colored("\n👋 Operación cancelada por el usuario", Colors.YELLOW)
    except Exception as e:
        print_colored(f"\n❌ Error inesperado: {e}", Colors.RED)
        sys.exit(1)

if __name__ == '__main__':
    main()
