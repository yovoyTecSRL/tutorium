#!/usr/bin/env python3
"""
Tutorium QA Runner (sin Odoo)
Ejecuta verificaciones de QA básicas en URLs especificadas.
"""

import argparse
import datetime
import requests
import sys
import time
from typing import List, Tuple


def check_url(url: str, timeout: int, retries: int) -> Tuple[bool, str, float]:
    """
    Verifica una URL específica.
    
    Returns:
        tuple: (success, status_message, response_time)
    """
    for attempt in range(retries + 1):
        try:
            start_time = time.time()
            response = requests.get(url, timeout=timeout)
            response_time = time.time() - start_time
            
            if response.status_code == 200:
                return True, f"✅ OK ({response.status_code})", response_time
            else:
                return False, f"❌ HTTP {response.status_code}", response_time
                
        except requests.exceptions.Timeout:
            if attempt < retries:
                time.sleep(1)  # Esperar antes del siguiente intento
                continue
            return False, "❌ TIMEOUT", 0.0
            
        except requests.exceptions.ConnectionError:
            if attempt < retries:
                time.sleep(1)
                continue
            return False, "❌ CONNECTION_ERROR", 0.0
            
        except Exception as e:
            if attempt < retries:
                time.sleep(1)
                continue
            return False, f"❌ ERROR: {str(e)}", 0.0
    
    return False, "❌ MAX_RETRIES_EXCEEDED", 0.0


def generate_qa_report(results: List[dict]) -> str:
    """Genera el reporte de QA en formato Markdown."""
    now_utc = datetime.datetime.utcnow()
    costa_rica_time = now_utc - datetime.timedelta(hours=6)
    
    total_urls = len(results)
    passed_urls = sum(1 for r in results if r['success'])
    failed_urls = total_urls - passed_urls
    
    report = f"""# Reporte QA — Tutorium (sin Odoo)

**📅 Fecha:** {costa_rica_time.strftime('%Y-%m-%d %H:%M:%S')} (Costa Rica)  
**🕐 Ejecutado:** {now_utc.strftime('%Y-%m-%d %H:%M:%S')} UTC

## 📊 Resumen

- **Total URLs:** {total_urls}
- **✅ Exitosas:** {passed_urls}
- **❌ Fallidas:** {failed_urls}
- **📈 Tasa éxito:** {(passed_urls/total_urls*100):.1f}%

## 🔍 Detalles por URL

"""
    
    for result in results:
        status_icon = "✅" if result['success'] else "❌"
        report += f"### {status_icon} {result['url']}\n\n"
        report += f"- **Estado:** {result['status']}\n"
        report += f"- **Tiempo respuesta:** {result['response_time']:.3f}s\n"
        
        if not result['success']:
            report += f"- **⚠️ Requiere atención**\n"
        
        report += "\n"
    
    if failed_urls > 0:
        report += f"""## 🚨 Acciones Requeridas

Se detectaron {failed_urls} URL(s) con problemas que requieren investigación:

"""
        for result in results:
            if not result['success']:
                report += f"- [ ] Investigar: `{result['url']}` - {result['status']}\n"
    
    report += """
## 🔗 Enlaces de Referencia

- [Dashboard Monitoreo](https://tutorium.sistemasorbix.com/admin)
- [Logs Servidor](https://tutorium.sistemasorbix.com/admin/logs)

---
*Reporte generado automáticamente | QA Nocturno Tutorium*
"""
    
    return report


def main():
    """Función principal del script."""
    parser = argparse.ArgumentParser(
        description="Ejecuta QA checks en URLs para Tutorium (sin Odoo)"
    )
    parser.add_argument(
        "--urls",
        required=True,
        help="URLs a verificar (separadas por newline)"
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=10,
        help="Timeout en segundos (default: 10)"
    )
    parser.add_argument(
        "--retries",
        type=int, 
        default=2,
        help="Número de reintentos (default: 2)"
    )
    parser.add_argument(
        "--report",
        default="qa_report.md",
        help="Archivo de reporte (default: qa_report.md)"
    )
    
    args = parser.parse_args()
    
    # Parsear URLs (puede venir como string multilínea)
    urls = [url.strip() for url in args.urls.strip().split('\n') if url.strip()]
    
    if not urls:
        print("❌ Error: No se proporcionaron URLs válidas", file=sys.stderr)
        return 1
    
    print(f"🔍 Iniciando QA check de {len(urls)} URL(s)...")
    
    results = []
    any_failed = False
    
    for i, url in enumerate(urls, 1):
        print(f"[{i}/{len(urls)}] Verificando: {url}")
        
        success, status, response_time = check_url(url, args.timeout, args.retries)
        
        result = {
            'url': url,
            'success': success,
            'status': status,
            'response_time': response_time
        }
        
        results.append(result)
        
        if not success:
            any_failed = True
        
        print(f"  → {status} ({response_time:.3f}s)")
    
    # Generar reporte
    report_content = generate_qa_report(results)
    
    try:
        with open(args.report, 'w', encoding='utf-8') as f:
            f.write(report_content)
        print(f"📝 Reporte guardado en: {args.report}")
    except Exception as e:
        print(f"⚠️ Error guardando reporte: {e}", file=sys.stderr)
    
    # Retornar código de salida apropiado
    if any_failed:
        print(f"❌ QA check completado con fallas")
        return 2  # Código específico para fallas de QA
    else:
        print(f"✅ QA check completado exitosamente")
        return 0


if __name__ == "__main__":
    sys.exit(main())
