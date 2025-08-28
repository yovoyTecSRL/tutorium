#!/usr/bin/env python3
"""
Sistema de Respaldos Automatizado - Tutorium Academy
====================================================
Sistema completo para gestión de respaldos con interfaz administrativa
"""

import os
import sys
import json
import asyncio
import subprocess
import schedule
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from pathlib import Path
from dataclasses import dataclass, asdict
from enum import Enum
import tarfile
import gzip
import shutil
import logging
from cryptography.fernet import Fernet
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import requests
from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean, Text, Float
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
import threading

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/tutorium/backup.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Configuración de base de datos
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://tutorium_user:tutorium2025secure@localhost/tutorium_academy")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class BackupStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

class BackupType(Enum):
    DATABASE = "database"
    FILES = "files"
    FULL_SYSTEM = "full_system"
    CUSTOM = "custom"

@dataclass
class BackupConfig:
    """Configuración de respaldo"""
    name: str
    type: BackupType
    schedule: str  # Cron expression
    enabled: bool
    retention_days: int
    compression: bool
    encryption: bool
    include_paths: List[str]
    exclude_patterns: List[str]
    destination: str
    notifications: bool
    cloud_sync: bool

# Modelos de base de datos
class BackupJob(Base):
    __tablename__ = "backup_jobs"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    type = Column(String)
    schedule = Column(String)
    enabled = Column(Boolean, default=True)
    retention_days = Column(Integer, default=7)
    compression = Column(Boolean, default=True)
    encryption = Column(Boolean, default=True)
    include_paths = Column(Text)
    exclude_patterns = Column(Text)
    destination = Column(String)
    notifications = Column(Boolean, default=True)
    cloud_sync = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class BackupHistory(Base):
    __tablename__ = "backup_history"
    
    id = Column(Integer, primary_key=True, index=True)
    job_id = Column(Integer)
    job_name = Column(String)
    status = Column(String)
    started_at = Column(DateTime)
    completed_at = Column(DateTime)
    file_path = Column(String)
    file_size = Column(Float)
    duration_seconds = Column(Float)
    error_message = Column(Text)
    success_rate = Column(Float)
    compressed_size = Column(Float)
    items_backed_up = Column(Integer)

# Crear tablas
Base.metadata.create_all(bind=engine)

# Modelos Pydantic
class BackupJobCreate(BaseModel):
    name: str
    type: str
    schedule: str
    enabled: bool = True
    retention_days: int = 7
    compression: bool = True
    encryption: bool = True
    include_paths: List[str] = []
    exclude_patterns: List[str] = []
    destination: str
    notifications: bool = True
    cloud_sync: bool = False

class BackupJobResponse(BaseModel):
    id: int
    name: str
    type: str
    schedule: str
    enabled: bool
    retention_days: int
    compression: bool
    encryption: bool
    include_paths: List[str]
    exclude_patterns: List[str]
    destination: str
    notifications: bool
    cloud_sync: bool
    created_at: datetime
    updated_at: datetime

class BackupHistoryResponse(BaseModel):
    id: int
    job_id: int
    job_name: str
    status: str
    started_at: datetime
    completed_at: Optional[datetime]
    file_path: Optional[str]
    file_size: Optional[float]
    duration_seconds: Optional[float]
    error_message: Optional[str]
    success_rate: Optional[float]
    compressed_size: Optional[float]
    items_backed_up: Optional[int]

class BackupManager:
    """Gestor principal de respaldos"""
    
    def __init__(self):
        self.backup_path = Path(os.getenv("BACKUP_STORAGE_PATH", "/opt/orbix/backups"))
        self.backup_path.mkdir(parents=True, exist_ok=True)
        self.encryption_key = os.getenv("BACKUP_ENCRYPTION_KEY", "default_key").encode()
        self.fernet = Fernet(Fernet.generate_key())
        self.running_jobs = {}
        self.scheduler_thread = None
        self.start_scheduler()
    
    def start_scheduler(self):
        """Iniciar el programador de respaldos"""
        if self.scheduler_thread is None or not self.scheduler_thread.is_alive():
            self.scheduler_thread = threading.Thread(target=self._run_scheduler, daemon=True)
            self.scheduler_thread.start()
            logger.info("Scheduler de respaldos iniciado")
    
    def _run_scheduler(self):
        """Ejecutar el programador en un hilo separado"""
        while True:
            schedule.run_pending()
            time.sleep(60)  # Verificar cada minuto
    
    def schedule_backup(self, job_config: BackupConfig):
        """Programar un respaldo"""
        def job_wrapper():
            asyncio.run(self.create_backup(job_config))
        
        if job_config.schedule == "hourly":
            schedule.every().hour.do(job_wrapper)
        elif job_config.schedule == "daily":
            schedule.every().day.at("02:00").do(job_wrapper)
        elif job_config.schedule == "weekly":
            schedule.every().week.do(job_wrapper)
        else:
            # Para expresiones cron más complejas
            schedule.every(1).minutes.do(job_wrapper)
        
        logger.info(f"Respaldo programado: {job_config.name} - {job_config.schedule}")
    
    async def create_backup(self, config: BackupConfig) -> Dict[str, Any]:
        """Crear respaldo según configuración"""
        start_time = datetime.utcnow()
        job_id = f"{config.name}_{int(start_time.timestamp())}"
        
        try:
            self.running_jobs[job_id] = {
                "config": config,
                "status": BackupStatus.RUNNING,
                "started_at": start_time,
                "progress": 0
            }
            
            # Crear directorio de respaldo
            backup_dir = self.backup_path / config.name / start_time.strftime("%Y%m%d_%H%M%S")
            backup_dir.mkdir(parents=True, exist_ok=True)
            
            result = None
            
            if config.type == BackupType.DATABASE:
                result = await self._backup_database(config, backup_dir)
            elif config.type == BackupType.FILES:
                result = await self._backup_files(config, backup_dir)
            elif config.type == BackupType.FULL_SYSTEM:
                result = await self._backup_full_system(config, backup_dir)
            elif config.type == BackupType.CUSTOM:
                result = await self._backup_custom(config, backup_dir)
            
            # Comprimir si está habilitado
            if config.compression:
                result = await self._compress_backup(result, backup_dir)
            
            # Encriptar si está habilitado
            if config.encryption:
                result = await self._encrypt_backup(result, backup_dir)
            
            # Limpiar respaldos antiguos
            await self._cleanup_old_backups(config)
            
            # Sincronizar con la nube si está habilitado
            if config.cloud_sync:
                await self._sync_to_cloud(result, config)
            
            # Enviar notificaciones
            if config.notifications:
                await self._send_notifications(config, result, True)
            
            end_time = datetime.utcnow()
            duration = (end_time - start_time).total_seconds()
            
            # Registrar en historial
            await self._save_backup_history(config, start_time, end_time, result, None, duration)
            
            self.running_jobs[job_id]["status"] = BackupStatus.COMPLETED
            self.running_jobs[job_id]["completed_at"] = end_time
            self.running_jobs[job_id]["result"] = result
            
            logger.info(f"Respaldo completado: {config.name} en {duration:.2f} segundos")
            
            return {
                "success": True,
                "job_id": job_id,
                "config": asdict(config),
                "result": result,
                "duration_seconds": duration
            }
            
        except Exception as e:
            error_msg = str(e)
            logger.error(f"Error en respaldo {config.name}: {error_msg}")
            
            # Registrar error en historial
            await self._save_backup_history(config, start_time, datetime.utcnow(), None, error_msg, 0)
            
            # Enviar notificación de error
            if config.notifications:
                await self._send_notifications(config, None, False, error_msg)
            
            self.running_jobs[job_id]["status"] = BackupStatus.FAILED
            self.running_jobs[job_id]["error"] = error_msg
            
            return {
                "success": False,
                "job_id": job_id,
                "config": asdict(config),
                "error": error_msg
            }
    
    async def _backup_database(self, config: BackupConfig, backup_dir: Path) -> Dict[str, Any]:
        """Crear respaldo de base de datos"""
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        db_backup_file = backup_dir / f"database_{timestamp}.sql"
        
        # Comando para PostgreSQL
        cmd = [
            "pg_dump",
            "--host=localhost",
            "--port=5432",
            "--username=tutorium_user",
            "--dbname=tutorium_academy",
            "--file=" + str(db_backup_file),
            "--verbose",
            "--clean",
            "--if-exists"
        ]
        
        process = subprocess.run(cmd, capture_output=True, text=True, 
                               env={**os.environ, 'PGPASSWORD': 'tutorium2025secure'})
        
        if process.returncode == 0:
            file_size = db_backup_file.stat().st_size
            return {
                "type": "database",
                "file_path": str(db_backup_file),
                "file_size": file_size,
                "success": True,
                "items_count": 1
            }
        else:
            raise Exception(f"Error en respaldo de BD: {process.stderr}")
    
    async def _backup_files(self, config: BackupConfig, backup_dir: Path) -> Dict[str, Any]:
        """Crear respaldo de archivos"""
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        files_backup_file = backup_dir / f"files_{timestamp}.tar"
        
        total_size = 0
        files_count = 0
        
        with tarfile.open(files_backup_file, "w") as tar:
            for include_path in config.include_paths:
                if os.path.exists(include_path):
                    for root, dirs, files in os.walk(include_path):
                        for file in files:
                            file_path = os.path.join(root, file)
                            # Aplicar filtros de exclusión
                            if not any(pattern in file_path for pattern in config.exclude_patterns):
                                tar.add(file_path, arcname=os.path.relpath(file_path, include_path))
                                total_size += os.path.getsize(file_path)
                                files_count += 1
        
        return {
            "type": "files",
            "file_path": str(files_backup_file),
            "file_size": files_backup_file.stat().st_size,
            "success": True,
            "items_count": files_count,
            "total_original_size": total_size
        }
    
    async def _backup_full_system(self, config: BackupConfig, backup_dir: Path) -> Dict[str, Any]:
        """Crear respaldo completo del sistema"""
        # Combinar respaldo de BD y archivos
        db_result = await self._backup_database(config, backup_dir)
        files_result = await self._backup_files(config, backup_dir)
        
        return {
            "type": "full_system",
            "database_backup": db_result,
            "files_backup": files_result,
            "success": True,
            "items_count": db_result["items_count"] + files_result["items_count"]
        }
    
    async def _backup_custom(self, config: BackupConfig, backup_dir: Path) -> Dict[str, Any]:
        """Crear respaldo personalizado"""
        # Implementar lógica personalizada según necesidades
        return {
            "type": "custom",
            "success": True,
            "items_count": 0
        }
    
    async def _compress_backup(self, backup_result: Dict[str, Any], backup_dir: Path) -> Dict[str, Any]:
        """Comprimir respaldo"""
        if "file_path" in backup_result:
            original_file = Path(backup_result["file_path"])
            compressed_file = original_file.with_suffix(original_file.suffix + ".gz")
            
            with open(original_file, 'rb') as f_in:
                with gzip.open(compressed_file, 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
            
            # Eliminar archivo original
            original_file.unlink()
            
            backup_result["file_path"] = str(compressed_file)
            backup_result["compressed_size"] = compressed_file.stat().st_size
            backup_result["compressed"] = True
        
        return backup_result
    
    async def _encrypt_backup(self, backup_result: Dict[str, Any], backup_dir: Path) -> Dict[str, Any]:
        """Encriptar respaldo"""
        if "file_path" in backup_result:
            original_file = Path(backup_result["file_path"])
            encrypted_file = original_file.with_suffix(original_file.suffix + ".enc")
            
            with open(original_file, 'rb') as f_in:
                encrypted_data = self.fernet.encrypt(f_in.read())
                with open(encrypted_file, 'wb') as f_out:
                    f_out.write(encrypted_data)
            
            # Eliminar archivo original
            original_file.unlink()
            
            backup_result["file_path"] = str(encrypted_file)
            backup_result["encrypted"] = True
        
        return backup_result
    
    async def _cleanup_old_backups(self, config: BackupConfig):
        """Limpiar respaldos antiguos"""
        cutoff_date = datetime.utcnow() - timedelta(days=config.retention_days)
        backup_job_dir = self.backup_path / config.name
        
        if backup_job_dir.exists():
            for backup_dir in backup_job_dir.iterdir():
                if backup_dir.is_dir():
                    try:
                        dir_date = datetime.strptime(backup_dir.name, "%Y%m%d_%H%M%S")
                        if dir_date < cutoff_date:
                            shutil.rmtree(backup_dir)
                            logger.info(f"Respaldo antiguo eliminado: {backup_dir}")
                    except ValueError:
                        # Ignorar directorios que no siguen el formato de fecha
                        pass
    
    async def _sync_to_cloud(self, backup_result: Dict[str, Any], config: BackupConfig):
        """Sincronizar respaldo con la nube"""
        # Implementar sincronización con AWS S3, Google Cloud, etc.
        logger.info(f"Sincronizando respaldo con la nube: {config.name}")
        pass
    
    async def _send_notifications(self, config: BackupConfig, result: Dict[str, Any], success: bool, error: str = None):
        """Enviar notificaciones de respaldo"""
        if not config.notifications:
            return
        
        subject = f"Respaldo {'Exitoso' if success else 'Fallido'}: {config.name}"
        
        if success:
            body = f"""
            Respaldo completado exitosamente:
            
            Trabajo: {config.name}
            Tipo: {config.type.value}
            Fecha: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')}
            Archivo: {result.get('file_path', 'N/A')}
            Tamaño: {result.get('file_size', 0) / 1024 / 1024:.2f} MB
            Elementos: {result.get('items_count', 0)}
            """
        else:
            body = f"""
            Error en respaldo:
            
            Trabajo: {config.name}
            Tipo: {config.type.value}
            Fecha: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')}
            Error: {error}
            """
        
        await self._send_email_notification(subject, body)
    
    async def _send_email_notification(self, subject: str, body: str):
        """Enviar notificación por email"""
        try:
            email_user = os.getenv("EMAIL_USER")
            email_pass = os.getenv("EMAIL_PASS")
            backup_email = os.getenv("BACKUP_EMAIL_ALERTS")
            
            if not all([email_user, email_pass, backup_email]):
                return
            
            msg = MIMEMultipart()
            msg['From'] = email_user
            msg['To'] = backup_email
            msg['Subject'] = subject
            
            msg.attach(MIMEText(body, 'plain'))
            
            server = smtplib.SMTP('smtp.gmail.com', 587)
            server.starttls()
            server.login(email_user, email_pass)
            server.send_message(msg)
            server.quit()
            
            logger.info(f"Notificación enviada: {subject}")
            
        except Exception as e:
            logger.error(f"Error enviando notificación: {e}")
    
    async def _save_backup_history(self, config: BackupConfig, start_time: datetime, 
                                 end_time: datetime, result: Dict[str, Any], 
                                 error: str, duration: float):
        """Guardar historial de respaldo"""
        db = SessionLocal()
        try:
            history = BackupHistory(
                job_name=config.name,
                status=BackupStatus.COMPLETED.value if result else BackupStatus.FAILED.value,
                started_at=start_time,
                completed_at=end_time,
                file_path=result.get('file_path') if result else None,
                file_size=result.get('file_size') if result else None,
                duration_seconds=duration,
                error_message=error,
                success_rate=100.0 if result else 0.0,
                compressed_size=result.get('compressed_size') if result else None,
                items_backed_up=result.get('items_count') if result else 0
            )
            db.add(history)
            db.commit()
        except Exception as e:
            logger.error(f"Error guardando historial: {e}")
        finally:
            db.close()
    
    def get_running_jobs(self) -> Dict[str, Any]:
        """Obtener trabajos en ejecución"""
        return {
            job_id: {
                "config": asdict(job_data["config"]),
                "status": job_data["status"].value,
                "started_at": job_data["started_at"].isoformat(),
                "progress": job_data.get("progress", 0)
            }
            for job_id, job_data in self.running_jobs.items()
        }
    
    def cancel_job(self, job_id: str) -> bool:
        """Cancelar trabajo de respaldo"""
        if job_id in self.running_jobs:
            self.running_jobs[job_id]["status"] = BackupStatus.CANCELLED
            return True
        return False

# Instancia global del gestor de respaldos
backup_manager = BackupManager()

# Dependency para obtener sesión de DB
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# FastAPI app para API de respaldos
backup_app = FastAPI(title="Tutorium Backup API", version="1.0.0")

@backup_app.post("/backup/jobs", response_model=BackupJobResponse)
async def create_backup_job(job: BackupJobCreate, db: Session = Depends(get_db)):
    """Crear nuevo trabajo de respaldo"""
    try:
        db_job = BackupJob(
            name=job.name,
            type=job.type,
            schedule=job.schedule,
            enabled=job.enabled,
            retention_days=job.retention_days,
            compression=job.compression,
            encryption=job.encryption,
            include_paths=json.dumps(job.include_paths),
            exclude_patterns=json.dumps(job.exclude_patterns),
            destination=job.destination,
            notifications=job.notifications,
            cloud_sync=job.cloud_sync
        )
        db.add(db_job)
        db.commit()
        db.refresh(db_job)
        
        # Programar el respaldo
        config = BackupConfig(
            name=job.name,
            type=BackupType(job.type),
            schedule=job.schedule,
            enabled=job.enabled,
            retention_days=job.retention_days,
            compression=job.compression,
            encryption=job.encryption,
            include_paths=job.include_paths,
            exclude_patterns=job.exclude_patterns,
            destination=job.destination,
            notifications=job.notifications,
            cloud_sync=job.cloud_sync
        )
        
        if job.enabled:
            backup_manager.schedule_backup(config)
        
        return BackupJobResponse(
            id=db_job.id,
            name=db_job.name,
            type=db_job.type,
            schedule=db_job.schedule,
            enabled=db_job.enabled,
            retention_days=db_job.retention_days,
            compression=db_job.compression,
            encryption=db_job.encryption,
            include_paths=json.loads(db_job.include_paths),
            exclude_patterns=json.loads(db_job.exclude_patterns),
            destination=db_job.destination,
            notifications=db_job.notifications,
            cloud_sync=db_job.cloud_sync,
            created_at=db_job.created_at,
            updated_at=db_job.updated_at
        )
        
    except Exception as e:
        logger.error(f"Error creando trabajo de respaldo: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@backup_app.get("/backup/jobs", response_model=List[BackupJobResponse])
async def get_backup_jobs(db: Session = Depends(get_db)):
    """Obtener todos los trabajos de respaldo"""
    jobs = db.query(BackupJob).all()
    return [
        BackupJobResponse(
            id=job.id,
            name=job.name,
            type=job.type,
            schedule=job.schedule,
            enabled=job.enabled,
            retention_days=job.retention_days,
            compression=job.compression,
            encryption=job.encryption,
            include_paths=json.loads(job.include_paths),
            exclude_patterns=json.loads(job.exclude_patterns),
            destination=job.destination,
            notifications=job.notifications,
            cloud_sync=job.cloud_sync,
            created_at=job.created_at,
            updated_at=job.updated_at
        )
        for job in jobs
    ]

@backup_app.post("/backup/execute/{job_id}")
async def execute_backup_now(job_id: int, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    """Ejecutar respaldo inmediatamente"""
    job = db.query(BackupJob).filter(BackupJob.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Trabajo de respaldo no encontrado")
    
    config = BackupConfig(
        name=job.name,
        type=BackupType(job.type),
        schedule=job.schedule,
        enabled=job.enabled,
        retention_days=job.retention_days,
        compression=job.compression,
        encryption=job.encryption,
        include_paths=json.loads(job.include_paths),
        exclude_patterns=json.loads(job.exclude_patterns),
        destination=job.destination,
        notifications=job.notifications,
        cloud_sync=job.cloud_sync
    )
    
    background_tasks.add_task(backup_manager.create_backup, config)
    
    return {"message": f"Respaldo iniciado: {job.name}"}

@backup_app.get("/backup/history", response_model=List[BackupHistoryResponse])
async def get_backup_history(limit: int = 50, db: Session = Depends(get_db)):
    """Obtener historial de respaldos"""
    history = db.query(BackupHistory).order_by(BackupHistory.started_at.desc()).limit(limit).all()
    return history

@backup_app.get("/backup/status")
async def get_backup_status():
    """Obtener estado actual de respaldos"""
    return {
        "running_jobs": backup_manager.get_running_jobs(),
        "system_status": "operational",
        "total_backups_today": len(backup_manager.running_jobs),
        "last_backup": datetime.utcnow().isoformat()
    }

@backup_app.delete("/backup/jobs/{job_id}")
async def delete_backup_job(job_id: int, db: Session = Depends(get_db)):
    """Eliminar trabajo de respaldo"""
    job = db.query(BackupJob).filter(BackupJob.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Trabajo de respaldo no encontrado")
    
    db.delete(job)
    db.commit()
    
    return {"message": f"Trabajo de respaldo eliminado: {job.name}"}

@backup_app.post("/backup/cancel/{job_id}")
async def cancel_backup_job(job_id: str):
    """Cancelar trabajo de respaldo en ejecución"""
    if backup_manager.cancel_job(job_id):
        return {"message": f"Trabajo cancelado: {job_id}"}
    else:
        raise HTTPException(status_code=404, detail="Trabajo no encontrado o no se puede cancelar")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(backup_app, host="0.0.0.0", port=8001)
