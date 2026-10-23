@echo off
title Base de Datos Aduana - PostgreSQL Local (Laboratorio 3)
echo ==============================================================
echo    INICIANDO SERVIDOR POSTGRESQL LOCAL PARA N8N (LAB 3)
echo ==============================================================
cd /d "%~dp0db-server"
node start_db.js
pause
