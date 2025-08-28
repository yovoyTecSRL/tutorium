#!/usr/bin/env python3
"""
Sistema de Puntuación y Corrección de Idiomas para Tutorium
Evalúa pronunciación, sintaxis y gramática en inglés y español.
"""

import json
import re
from typing import Dict, List, Tuple
from datetime import datetime


class LanguageScoringSystem:
    """Sistema de puntuación para habilidades lingüísticas."""
    
    def __init__(self):
        self.supported_languages = ['en', 'es']
        self.scoring_weights = {
            'pronunciation': 0.4,
            'grammar': 0.3,
            'syntax': 0.2,
            'vocabulary': 0.1
        }
        
        # Patrones comunes de errores por idioma
        self.common_errors = {
            'en': {
                'grammar': [
                    {'pattern': r'\b(he|she|it) (are|were)\b', 'correction': 'he/she/it is/was'},
                    {'pattern': r'\b(I|you|we|they) (is|was)\b', 'correction': 'I/you/we/they are/were'},
                    {'pattern': r'\ba apple\b', 'correction': 'an apple'},
                ],
                'syntax': [
                    {'pattern': r'\b(very|really) (good|bad|nice)\b', 'suggestion': 'Use more specific adjectives'},
                ]
            },
            'es': {
                'grammar': [
                    {'pattern': r'\bla problema\b', 'correction': 'el problema'},
                    {'pattern': r'\bel agua\b', 'correction': 'el agua (but feminine)'},
                    {'pattern': r'\besta bueno\b', 'correction': 'está bueno'},
                ],
                'syntax': [
                    {'pattern': r'\byo soy teniendo\b', 'correction': 'yo tengo'},
                ]
            }
        }

    def analyze_text(self, text: str, language: str = 'en') -> Dict:
        """Analiza un texto y retorna puntuaciones y correcciones."""
        if language not in self.supported_languages:
            raise ValueError(f"Language {language} not supported")
        
        analysis = {
            'language': language,
            'timestamp': datetime.utcnow().isoformat(),
            'text_length': len(text.split()),
            'scores': {},
            'corrections': [],
            'suggestions': [],
            'overall_score': 0
        }
        
        # Análisis de gramática
        grammar_score, grammar_corrections = self._analyze_grammar(text, language)
        analysis['scores']['grammar'] = grammar_score
        analysis['corrections'].extend(grammar_corrections)
        
        # Análisis de sintaxis
        syntax_score, syntax_suggestions = self._analyze_syntax(text, language)
        analysis['scores']['syntax'] = syntax_score
        analysis['suggestions'].extend(syntax_suggestions)
        
        # Análisis de vocabulario
        vocabulary_score = self._analyze_vocabulary(text, language)
        analysis['scores']['vocabulary'] = vocabulary_score
        
        # Puntuación general (pronunciación se evalúa en frontend)
        analysis['scores']['pronunciation'] = 85  # Placeholder para audio
        analysis['overall_score'] = self._calculate_overall_score(analysis['scores'])
        
        return analysis

    def _analyze_grammar(self, text: str, language: str) -> Tuple[int, List[Dict]]:
        """Analiza errores gramaticales."""
        corrections = []
        errors_found = 0
        total_words = len(text.split())
        
        if language in self.common_errors:
            for error in self.common_errors[language].get('grammar', []):
                matches = re.finditer(error['pattern'], text, re.IGNORECASE)
                for match in matches:
                    corrections.append({
                        'type': 'grammar',
                        'error': match.group(),
                        'correction': error['correction'],
                        'position': match.span()
                    })
                    errors_found += 1
        
        # Calcular puntuación (menos errores = mejor puntuación)
        error_rate = errors_found / max(total_words, 1)
        score = max(0, int(100 - (error_rate * 100)))
        
        return score, corrections

    def _analyze_syntax(self, text: str, language: str) -> Tuple[int, List[Dict]]:
        """Analiza estructura sintáctica."""
        suggestions = []
        issues_found = 0
        
        if language in self.common_errors:
            for pattern in self.common_errors[language].get('syntax', []):
                matches = re.finditer(pattern['pattern'], text, re.IGNORECASE)
                for match in matches:
                    suggestions.append({
                        'type': 'syntax',
                        'issue': match.group(),
                        'suggestion': pattern.get('suggestion', pattern.get('correction')),
                        'position': match.span()
                    })
                    issues_found += 1
        
        # Puntuación sintáctica
        sentence_count = len(re.split(r'[.!?]+', text))
        complexity_score = min(100, sentence_count * 10)  # Más oraciones = más complejo
        issue_penalty = issues_found * 10
        score = max(0, complexity_score - issue_penalty)
        
        return score, suggestions

    def _analyze_vocabulary(self, text: str, language: str) -> int:
        """Analiza riqueza del vocabulario."""
        words = text.lower().split()
        unique_words = set(words)
        
        # Calcular ratio de palabras únicas
        if len(words) == 0:
            return 0
        
        uniqueness_ratio = len(unique_words) / len(words)
        vocabulary_score = int(uniqueness_ratio * 100)
        
        # Bonus por longitud de palabras (vocabulario más avanzado)
        avg_word_length = sum(len(word) for word in unique_words) / len(unique_words)
        length_bonus = min(20, int((avg_word_length - 3) * 5))
        
        return min(100, vocabulary_score + length_bonus)

    def _calculate_overall_score(self, scores: Dict[str, int]) -> int:
        """Calcula puntuación general ponderada."""
        total_score = 0
        for skill, weight in self.scoring_weights.items():
            if skill in scores:
                total_score += scores[skill] * weight
        
        return int(total_score)

    def get_improvement_advice(self, analysis: Dict) -> List[str]:
        """Genera consejos para mejorar según el idioma y puntuaciones."""
        advice = []
        language = analysis['language']
        scores = analysis['scores']
        
        # Consejos basados en puntuaciones bajas
        if scores.get('grammar', 100) < 70:
            if language == 'en':
                advice.append("Focus on subject-verb agreement and article usage (a/an/the)")
                advice.append("Practice verb tenses, especially present and past simple")
            else:  # español
                advice.append("Practica la concordancia de género y número (la/el, las/los)")
                advice.append("Revisa los tiempos verbales básicos (presente, pretérito)")
        
        if scores.get('vocabulary', 100) < 60:
            if language == 'en':
                advice.append("Expand vocabulary by learning 5 new words daily")
                advice.append("Use synonyms to avoid word repetition")
            else:  # español
                advice.append("Amplía tu vocabulario aprendiendo 5 palabras nuevas diariamente")
                advice.append("Usa sinónimos para evitar repetir palabras")
        
        if scores.get('syntax', 100) < 65:
            if language == 'en':
                advice.append("Practice sentence variety: mix simple and complex sentences")
                advice.append("Learn connecting words (however, therefore, moreover)")
            else:  # español
                advice.append("Practica variedad en oraciones: mezcla simples y complejas")
                advice.append("Aprende conectores (sin embargo, por lo tanto, además)")
        
        return advice

    def export_progress_report(self, user_analyses: List[Dict]) -> Dict:
        """Exporta reporte de progreso del estudiante."""
        if not user_analyses:
            return {}
        
        # Calcular promedios y tendencias
        avg_scores = {}
        for skill in ['grammar', 'syntax', 'vocabulary', 'pronunciation']:
            scores = [a['scores'].get(skill, 0) for a in user_analyses if skill in a['scores']]
            avg_scores[skill] = sum(scores) / len(scores) if scores else 0
        
        # Tendencia (comparar primeros vs últimos análisis)
        recent_analyses = user_analyses[-5:]  # Últimos 5
        old_analyses = user_analyses[:5]      # Primeros 5
        
        trends = {}
        for skill in avg_scores.keys():
            recent_avg = sum(a['scores'].get(skill, 0) for a in recent_analyses) / len(recent_analyses)
            old_avg = sum(a['scores'].get(skill, 0) for a in old_analyses) / len(old_analyses)
            trends[skill] = recent_avg - old_avg
        
        return {
            'total_sessions': len(user_analyses),
            'average_scores': avg_scores,
            'trends': trends,
            'current_level': self._determine_level(avg_scores),
            'generated_at': datetime.utcnow().isoformat()
        }

    def _determine_level(self, avg_scores: Dict[str, float]) -> str:
        """Determina el nivel del estudiante basado en puntuaciones promedio."""
        overall_avg = sum(avg_scores.values()) / len(avg_scores)
        
        if overall_avg >= 90:
            return "Advanced (C1-C2)"
        elif overall_avg >= 75:
            return "Upper Intermediate (B2)"
        elif overall_avg >= 60:
            return "Intermediate (B1)"
        elif overall_avg >= 45:
            return "Pre-Intermediate (A2)"
        else:
            return "Beginner (A1)"


def main():
    """Función de prueba del sistema."""
    scorer = LanguageScoringSystem()
    
    # Ejemplo en inglés
    english_text = "He are very good in english. I wants to learning more."
    analysis_en = scorer.analyze_text(english_text, 'en')
    
    print("=== English Analysis ===")
    print(f"Overall Score: {analysis_en['overall_score']}/100")
    print(f"Grammar: {analysis_en['scores']['grammar']}/100")
    print(f"Syntax: {analysis_en['scores']['syntax']}/100")
    print(f"Vocabulary: {analysis_en['scores']['vocabulary']}/100")
    print("\nCorrections needed:")
    for correction in analysis_en['corrections']:
        print(f"- {correction['error']} → {correction['correction']}")
    
    print("\nImprovement advice:")
    advice = scorer.get_improvement_advice(analysis_en)
    for tip in advice:
        print(f"- {tip}")
    
    # Ejemplo en español
    spanish_text = "La problema es que yo soy teniendo dificultades con la gramática."
    analysis_es = scorer.analyze_text(spanish_text, 'es')
    
    print("\n=== Spanish Analysis ===")
    print(f"Puntuación General: {analysis_es['overall_score']}/100")
    print(f"Gramática: {analysis_es['scores']['grammar']}/100")
    print(f"Sintaxis: {analysis_es['scores']['syntax']}/100")
    print(f"Vocabulario: {analysis_es['scores']['vocabulary']}/100")
    print("\nCorrecciones necesarias:")
    for correction in analysis_es['corrections']:
        print(f"- {correction['error']} → {correction['correction']}")


if __name__ == "__main__":
    main()
