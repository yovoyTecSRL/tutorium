# Configuración del Sistema de Puntuación de Idiomas - Tutorium
# Este archivo contiene la configuración principal del sistema

import os
from dataclasses import dataclass
from typing import Dict, List, Tuple

@dataclass
class LanguageConfig:
    """Configuración específica para cada idioma."""
    code: str
    name: str
    flag: str
    grammar_rules: List[str]
    common_errors: List[Tuple[str, str]]  # (error, corrección)
    vocabulary_levels: Dict[str, List[str]]
    pronunciation_phonemes: List[str]

@dataclass
class ScoringConfig:
    """Configuración de los pesos de puntuación."""
    pronunciation_weight: float = 0.40
    grammar_weight: float = 0.30
    syntax_weight: float = 0.20
    vocabulary_weight: float = 0.10
    
    # Umbrales de nivel
    beginner_threshold: int = 60
    intermediate_threshold: int = 75
    advanced_threshold: int = 85

class SystemConfig:
    """Configuración principal del sistema."""
    
    # Configuración de idiomas
    LANGUAGES = {
        'en': LanguageConfig(
            code='en',
            name='English',
            flag='🇺🇸',
            grammar_rules=[
                'subject_verb_agreement',
                'article_usage',
                'tense_consistency',
                'preposition_usage',
                'plural_forms'
            ],
            common_errors=[
                ('he are', 'he is'),
                ('she have', 'she has'),
                ('I go to home', 'I go home'),
                ('a apple', 'an apple'),
                ('much people', 'many people'),
                ('I am agree', 'I agree'),
                ('I have 20 years old', 'I am 20 years old'),
                ('I am boring', 'I am bored'),
                ('make a party', 'have a party'),
                ('I am study', 'I am studying')
            ],
            vocabulary_levels={
                'beginner': [
                    'hello', 'goodbye', 'please', 'thank', 'yes', 'no',
                    'water', 'food', 'house', 'family', 'friend', 'work',
                    'good', 'bad', 'big', 'small', 'hot', 'cold'
                ],
                'intermediate': [
                    'although', 'however', 'therefore', 'moreover',
                    'environment', 'opportunity', 'responsibility',
                    'achievement', 'experience', 'knowledge'
                ],
                'advanced': [
                    'nevertheless', 'consequently', 'furthermore',
                    'entrepreneurship', 'infrastructure', 'sustainability',
                    'comprehensive', 'unprecedented', 'articulate'
                ]
            },
            pronunciation_phonemes=[
                '/θ/', '/ð/', '/ɪ/', '/iː/', '/ʊ/', '/uː/',
                '/æ/', '/ʌ/', '/ɑː/', '/ɔː/', '/eɪ/', '/aɪ/',
                '/ɔɪ/', '/aʊ/', '/əʊ/', '/ɪə/', '/eə/', '/ʊə/'
            ]
        ),
        'es': LanguageConfig(
            code='es',
            name='Español',
            flag='🇪🇸',
            grammar_rules=[
                'gender_agreement',
                'ser_estar_usage',
                'subjunctive_mood',
                'por_para_usage',
                'reflexive_pronouns'
            ],
            common_errors=[
                ('soy estudiando', 'estoy estudiando'),
                ('tengo hambre', 'tengo hambre'),  # correcto
                ('es importante que tienes', 'es importante que tengas'),
                ('para siempre', 'para siempre'),  # correcto
                ('me gusta que tu vienes', 'me gusta que vengas'),
                ('más mejor', 'mejor'),
                ('el agua está calor', 'el agua está caliente'),
                ('mi trabajo es muy estresoso', 'mi trabajo es muy estresante'),
                ('voy a hacer una pregunta', 'voy a hacer una pregunta'),  # correcto
                ('necesito que me ayudas', 'necesito que me ayudes')
            ],
            vocabulary_levels={
                'principiante': [
                    'hola', 'adiós', 'por favor', 'gracias', 'sí', 'no',
                    'agua', 'comida', 'casa', 'familia', 'amigo', 'trabajo',
                    'bueno', 'malo', 'grande', 'pequeño', 'caliente', 'frío'
                ],
                'intermedio': [
                    'aunque', 'sin embargo', 'por lo tanto', 'además',
                    'medio ambiente', 'oportunidad', 'responsabilidad',
                    'logro', 'experiencia', 'conocimiento'
                ],
                'avanzado': [
                    'no obstante', 'en consecuencia', 'por otra parte',
                    'emprendimiento', 'infraestructura', 'sostenibilidad',
                    'exhaustivo', 'sin precedentes', 'articular'
                ]
            },
            pronunciation_phonemes=[
                '/r/', '/rr/', '/ñ/', '/ll/', '/j/', '/x/',
                '/θ/', '/s/', '/b/', '/β/', '/d/', '/ð/',
                '/g/', '/ɣ/', '/p/', '/t/', '/k/'
            ]
        )
    }
    
    # Configuración de puntuación
    SCORING = ScoringConfig()
    
    # Configuración de la API
    API_HOST = os.getenv('API_HOST', '127.0.0.1')
    API_PORT = int(os.getenv('API_PORT', '5000'))
    API_DEBUG = os.getenv('API_DEBUG', 'True').lower() == 'true'
    
    # Configuración de base de datos
    DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///tutorium_language.db')
    
    # Configuración de archivos
    UPLOAD_FOLDER = os.getenv('UPLOAD_FOLDER', 'uploads/')
    MAX_FILE_SIZE = int(os.getenv('MAX_FILE_SIZE', '10485760'))  # 10MB
    
    # Configuración de logging
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
    LOG_FILE = os.getenv('LOG_FILE', 'logs/language_api.log')
    
    # Configuración de seguridad
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    
    # Límites de análisis
    MAX_TEXT_LENGTH = int(os.getenv('MAX_TEXT_LENGTH', '5000'))
    MIN_TEXT_LENGTH = int(os.getenv('MIN_TEXT_LENGTH', '10'))
    
    # Configuración de cache
    CACHE_TIMEOUT = int(os.getenv('CACHE_TIMEOUT', '3600'))  # 1 hora
    
    @classmethod
    def get_language_config(cls, language_code: str) -> LanguageConfig:
        """Obtiene la configuración para un idioma específico."""
        return cls.LANGUAGES.get(language_code, cls.LANGUAGES['en'])
    
    @classmethod
    def is_supported_language(cls, language_code: str) -> bool:
        """Verifica si un idioma está soportado."""
        return language_code in cls.LANGUAGES
    
    @classmethod
    def get_supported_languages(cls) -> List[Dict[str, str]]:
        """Retorna la lista de idiomas soportados."""
        return [
            {
                'code': lang.code,
                'name': lang.name,
                'flag': lang.flag
            }
            for lang in cls.LANGUAGES.values()
        ]

# Configuración de desarrollo
class DevelopmentConfig(SystemConfig):
    """Configuración para entorno de desarrollo."""
    API_DEBUG = True
    DATABASE_URL = 'sqlite:///dev_tutorium_language.db'
    LOG_LEVEL = 'DEBUG'

# Configuración de producción
class ProductionConfig(SystemConfig):
    """Configuración para entorno de producción."""
    API_DEBUG = False
    LOG_LEVEL = 'WARNING'
    
    # En producción, estas variables DEBEN estar configuradas
    SECRET_KEY = os.getenv('SECRET_KEY')
    DATABASE_URL = os.getenv('DATABASE_URL')
    
    def __post_init__(self):
        if not self.SECRET_KEY:
            raise ValueError("SECRET_KEY debe estar configurada en producción")
        if not self.DATABASE_URL:
            raise ValueError("DATABASE_URL debe estar configurada en producción")

# Función para obtener la configuración según el entorno
def get_config():
    """Retorna la configuración apropiada según el entorno."""
    env = os.getenv('FLASK_ENV', 'development')
    
    if env == 'production':
        return ProductionConfig()
    else:
        return DevelopmentConfig()

# Instancia global de configuración
config = get_config()
