#!/usr/bin/env python3
"""
Tests para el Sistema de Puntuación de Idiomas - Tutorium
Pruebas unitarias para validar funcionalidad del backend.
"""

import unittest
import sys
import os
import json

# Agregar el directorio tools al path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'tools'))

from language_scoring_system import LanguageScoringSystem
from config import SystemConfig


class TestLanguageScoringSystem(unittest.TestCase):
    """Tests para el sistema de puntuación de idiomas."""
    
    def setUp(self):
        """Configuración inicial para cada test."""
        self.scorer = LanguageScoringSystem()
    
    def test_english_grammar_analysis(self):
        """Test análisis de gramática en inglés."""
        text = "He are going to the store"
        result = self.scorer.analyze_text(text, 'en')
        
        self.assertIn('scores', result)
        self.assertIn('corrections', result)
        self.assertTrue(len(result['corrections']) > 0)
        
        # Verificar que detecta el error "he are"
        corrections = result['corrections']
        error_found = any('he are' in str(corr) for corr in corrections)
        self.assertTrue(error_found)
    
    def test_spanish_grammar_analysis(self):
        """Test análisis de gramática en español."""
        text = "Yo soy estudiando español"
        result = self.scorer.analyze_text(text, 'es')
        
        self.assertIn('scores', result)
        self.assertIn('corrections', result)
        self.assertTrue(len(result['corrections']) > 0)
        
        # Verificar que detecta el error "soy estudiando"
        corrections = result['corrections']
        error_found = any('soy estudiando' in str(corr) for corr in corrections)
        self.assertTrue(error_found)
    
    def test_vocabulary_scoring(self):
        """Test puntuación de vocabulario."""
        # Texto con vocabulario básico
        basic_text = "I have a cat and a dog"
        basic_result = self.scorer.analyze_text(basic_text, 'en')
        
        # Texto con vocabulario avanzado
        advanced_text = "The unprecedented infrastructure development"
        advanced_result = self.scorer.analyze_text(advanced_text, 'en')
        
        # El vocabulario avanzado debería tener mayor puntuación
        self.assertGreater(
            advanced_result['scores']['vocabulary'],
            basic_result['scores']['vocabulary']
        )
    
    def test_syntax_complexity(self):
        """Test análisis de complejidad sintáctica."""
        # Oración simple
        simple_text = "I like cats"
        simple_result = self.scorer.analyze_text(simple_text, 'en')
        
        # Oración compleja
        complex_text = "Although I like cats, I prefer dogs because they are loyal"
        complex_result = self.scorer.analyze_text(complex_text, 'en')
        
        # La oración compleja debería tener mayor puntuación sintáctica
        self.assertGreater(
            complex_result['scores']['syntax'],
            simple_result['scores']['syntax']
        )
    
    def test_improvement_advice(self):
        """Test generación de consejos de mejora."""
        text = "He are good student"
        analysis = self.scorer.analyze_text(text, 'en')
        advice = self.scorer.get_improvement_advice(analysis)
        
        self.assertIsInstance(advice, list)
        self.assertTrue(len(advice) > 0)
        
        # Debería incluir consejo sobre concordancia
        advice_text = ' '.join(advice).lower()
        self.assertTrue(
            'agreement' in advice_text or 
            'concordancia' in advice_text
        )
    
    def test_progress_report(self):
        """Test generación de reporte de progreso."""
        # Simular múltiples análisis
        analyses = []
        texts = [
            "I am student",
            "I am a student",
            "I am a good student who studies hard"
        ]
        
        for text in texts:
            analysis = self.scorer.analyze_text(text, 'en')
            analyses.append(analysis)
        
        report = self.scorer.export_progress_report(analyses)
        
        self.assertIn('total_sessions', report)
        self.assertIn('average_scores', report)
        self.assertIn('improvement_trend', report)
        self.assertEqual(report['total_sessions'], len(texts))
    
    def test_empty_text_handling(self):
        """Test manejo de texto vacío."""
        result = self.scorer.analyze_text("", 'en')
        
        # Debería manejar graciosamente el texto vacío
        self.assertIn('scores', result)
        self.assertEqual(result['scores']['overall'], 0)
    
    def test_unsupported_language(self):
        """Test manejo de idioma no soportado."""
        with self.assertRaises(ValueError):
            self.scorer.analyze_text("Hello world", 'fr')
    
    def test_score_ranges(self):
        """Test que las puntuaciones estén en rangos válidos."""
        text = "This is a well-written sentence with good grammar."
        result = self.scorer.analyze_text(text, 'en')
        
        scores = result['scores']
        for score_type, score in scores.items():
            self.assertGreaterEqual(score, 0, f"{score_type} score below 0")
            self.assertLessEqual(score, 100, f"{score_type} score above 100")


class TestSystemConfig(unittest.TestCase):
    """Tests para la configuración del sistema."""
    
    def test_supported_languages(self):
        """Test idiomas soportados."""
        languages = SystemConfig.get_supported_languages()
        
        self.assertIsInstance(languages, list)
        self.assertTrue(len(languages) >= 2)
        
        # Verificar que inglés y español estén incluidos
        language_codes = [lang['code'] for lang in languages]
        self.assertIn('en', language_codes)
        self.assertIn('es', language_codes)
    
    def test_language_config_retrieval(self):
        """Test obtención de configuración de idioma."""
        en_config = SystemConfig.get_language_config('en')
        es_config = SystemConfig.get_language_config('es')
        
        self.assertEqual(en_config.code, 'en')
        self.assertEqual(es_config.code, 'es')
        
        # Verificar que tienen errores comunes definidos
        self.assertTrue(len(en_config.common_errors) > 0)
        self.assertTrue(len(es_config.common_errors) > 0)
    
    def test_scoring_weights(self):
        """Test configuración de pesos de puntuación."""
        scoring = SystemConfig.SCORING
        
        # Los pesos deberían sumar 1.0
        total_weight = (
            scoring.pronunciation_weight +
            scoring.grammar_weight +
            scoring.syntax_weight +
            scoring.vocabulary_weight
        )
        
        self.assertAlmostEqual(total_weight, 1.0, places=2)


class TestIntegration(unittest.TestCase):
    """Tests de integración del sistema completo."""
    
    def setUp(self):
        """Configuración inicial."""
        self.scorer = LanguageScoringSystem()
    
    def test_complete_analysis_workflow(self):
        """Test flujo completo de análisis."""
        # Texto de ejemplo con varios tipos de errores
        text = "He are a very good students who study hardly"
        
        # Análisis completo
        result = self.scorer.analyze_text(text, 'en')
        
        # Verificar estructura de respuesta
        expected_keys = ['scores', 'corrections', 'suggestions', 'level']
        for key in expected_keys:
            self.assertIn(key, result)
        
        # Verificar que detecta múltiples errores
        self.assertTrue(len(result['corrections']) >= 2)
        
        # Generar consejos
        advice = self.scorer.get_improvement_advice(result)
        self.assertTrue(len(advice) > 0)
    
    def test_bilingual_analysis(self):
        """Test análisis en ambos idiomas."""
        en_text = "I have been studying English for two years"
        es_text = "He estado estudiando español por dos años"
        
        en_result = self.scorer.analyze_text(en_text, 'en')
        es_result = self.scorer.analyze_text(es_text, 'es')
        
        # Ambos deberían tener estructuras similares
        self.assertEqual(
            set(en_result.keys()),
            set(es_result.keys())
        )
        
        # Ambos deberían tener puntuaciones válidas
        for result in [en_result, es_result]:
            self.assertGreater(result['scores']['overall'], 0)


def run_tests():
    """Ejecuta todas las pruebas."""
    print("🧪 Ejecutando tests del Sistema de Puntuación de Idiomas...")
    print("=" * 60)
    
    # Ejecutar tests
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromModule(sys.modules[__name__])
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Resumen de resultados
    print("\n" + "=" * 60)
    print(f"📊 Resumen de Tests:")
    print(f"   ✅ Tests ejecutados: {result.testsRun}")
    print(f"   ❌ Fallos: {len(result.failures)}")
    print(f"   🚫 Errores: {len(result.errors)}")
    
    if result.failures:
        print(f"\n💥 Fallos encontrados:")
        for test, traceback in result.failures:
            print(f"   - {test}: {traceback.split('\\n')[-2]}")
    
    if result.errors:
        print(f"\n🚨 Errores encontrados:")
        for test, traceback in result.errors:
            print(f"   - {test}: {traceback.split('\\n')[-2]}")
    
    success = len(result.failures) == 0 and len(result.errors) == 0
    
    if success:
        print(f"\n🎉 ¡Todos los tests pasaron exitosamente!")
    else:
        print(f"\n⚠️  Algunos tests fallaron. Revisa los errores arriba.")
    
    return success


if __name__ == '__main__':
    success = run_tests()
    sys.exit(0 if success else 1)
