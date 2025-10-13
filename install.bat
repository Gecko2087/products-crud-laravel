@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo Products CRUD API - Instalacion Automatica
echo ==========================================
echo.

echo Sistema operativo detectado: Windows
echo.

REM Verificar PHP
where php >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: PHP no esta instalado.
    echo Por favor instala PHP 8.1 o superior y vuelve a ejecutar este script.
    echo.
    echo Opciones recomendadas para Windows:
    echo - Laragon: https://laragon.org/
    echo - XAMPP: https://www.apachefriends.org/
    echo - WAMP: https://www.wampserver.com/
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('php -r "echo PHP_VERSION;"') do set PHP_VERSION=%%i
echo [OK] PHP version: %PHP_VERSION%

REM Verificar Composer
where composer >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Composer no esta instalado.
    echo Descargalo desde: https://getcomposer.org/download/
    pause
    exit /b 1
)

echo [OK] Composer instalado correctamente
echo.

REM Instalar dependencias
echo [1/7] Instalando dependencias de Composer...
call composer install --no-interaction --prefer-dist --optimize-autoloader 2>nul

if %errorlevel% neq 0 (
    echo ERROR: Fallo la instalacion de dependencias.
    echo Intenta ejecutar manualmente: composer install
    pause
    exit /b 1
)

echo [OK] Dependencias instaladas
echo.

REM Create necessary directories
echo [2/7] Creando directorios necesarios...
if not exist "storage\framework\cache\data" mkdir storage\framework\cache\data 2>nul
if not exist "storage\framework\sessions" mkdir storage\framework\sessions 2>nul
if not exist "storage\framework\views" mkdir storage\framework\views 2>nul
if not exist "storage\logs" mkdir storage\logs 2>nul
if not exist "database" mkdir database 2>nul

echo [OK] Directorios creados
echo.

REM Create .env file
echo [3/7] Configurando archivo de entorno...
if not exist ".env" (
    copy .env.example .env >nul 2>&1
    echo [OK] Archivo .env creado
) else (
    echo [OK] Archivo .env ya existe
)

REM Generate application key
echo [4/7] Generando clave de aplicacion...
php artisan key:generate --no-interaction --force >nul 2>&1

echo [OK] Clave de aplicacion generada
echo.

echo.
echo ==========================================
echo [5/7] Configuracion de Base de Datos
echo ==========================================
echo.
echo Opciones disponibles:
echo   1. SQLite (rapido, recomendado para pruebas)
echo   2. MySQL (produccion, requiere servidor MySQL/MariaDB)
echo.

set /p db_choice="Selecciona el tipo de base de datos (1 o 2) [1]: "
if "%db_choice%"=="" set db_choice=1

if "%db_choice%"=="1" (
    echo.
    echo [OK] Configurando SQLite...
    powershell -Command "(gc .env) -replace 'DB_CONNECTION=.*', 'DB_CONNECTION=sqlite' | Out-File -encoding ASCII .env"
    powershell -Command "(gc .env) -replace 'DB_HOST=.*', '# DB_HOST=127.0.0.1' | Out-File -encoding ASCII .env"
    powershell -Command "(gc .env) -replace 'DB_PORT=.*', '# DB_PORT=3306' | Out-File -encoding ASCII .env"
    powershell -Command "(gc .env) -replace 'DB_DATABASE=.*', '# DB_DATABASE=products_db' | Out-File -encoding ASCII .env"
    powershell -Command "(gc .env) -replace 'DB_USERNAME=.*', '# DB_USERNAME=root' | Out-File -encoding ASCII .env"
    powershell -Command "(gc .env) -replace 'DB_PASSWORD=.*', '# DB_PASSWORD=' | Out-File -encoding ASCII .env"
    
    if not exist "database\database.sqlite" (
        type nul > database\database.sqlite
    )
    echo [OK] Base de datos SQLite configurada
    
) else if "%db_choice%"=="2" (
    echo.
    echo Configuracion de MySQL:
    echo.
    
    set /p db_host="Host MySQL [127.0.0.1]: "
    if "%db_host%"=="" set db_host=127.0.0.1
    
    set /p db_port="Puerto MySQL [3306]: "
    if "%db_port%"=="" set db_port=3306
    
    set /p db_name="Nombre de la base de datos [products_db]: "
    if "%db_name%"=="" set db_name=products_db
    
    set /p db_user="Usuario MySQL [root]: "
    if "%db_user%"=="" set db_user=root
    
    set /p db_pass="Contrasena MySQL (presiona Enter si no tiene): "
    
    echo.
    echo [OK] Actualizando archivo .env...
    powershell -Command "(gc .env) -replace 'DB_CONNECTION=.*', 'DB_CONNECTION=mysql' | Out-File -encoding ASCII .env"
    powershell -Command "(gc .env) -replace 'DB_HOST=.*', 'DB_HOST=%db_host%' | Out-File -encoding ASCII .env"
    powershell -Command "(gc .env) -replace 'DB_PORT=.*', 'DB_PORT=%db_port%' | Out-File -encoding ASCII .env"
    powershell -Command "(gc .env) -replace 'DB_DATABASE=.*', 'DB_DATABASE=%db_name%' | Out-File -encoding ASCII .env"
    powershell -Command "(gc .env) -replace 'DB_USERNAME=.*', 'DB_USERNAME=%db_user%' | Out-File -encoding ASCII .env"
    powershell -Command "(gc .env) -replace 'DB_PASSWORD=.*', 'DB_PASSWORD=%db_pass%' | Out-File -encoding ASCII .env"
    
    echo [OK] Archivo .env actualizado
    echo.
    echo Intentando crear la base de datos '%db_name%'...
    
    if "%db_pass%"=="" (
        mysql -h%db_host% -P%db_port% -u%db_user% -e "CREATE DATABASE IF NOT EXISTS %db_name% CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>nul
    ) else (
        mysql -h%db_host% -P%db_port% -u%db_user% -p%db_pass% -e "CREATE DATABASE IF NOT EXISTS %db_name% CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>nul
    )
    
    if !ERRORLEVEL! EQU 0 (
        echo [OK] Base de datos '%db_name%' creada/verificada exitosamente
    ) else (
        echo [ADVERTENCIA] No se pudo crear la base de datos automaticamente.
        echo.
        echo Por favor creala manualmente antes de continuar:
        echo   1. Abre phpMyAdmin o tu cliente MySQL
        echo   2. Ejecuta: CREATE DATABASE %db_name%;
        echo   3. Presiona cualquier tecla cuando hayas terminado
        echo.
        pause
    )
) else (
    echo ERROR: Opcion invalida. Ejecuta el script nuevamente.
    pause
    exit /b 1
)

REM Run migrations
echo.
echo [6/7] Ejecutando migraciones de base de datos...
php artisan migrate --force 2>nul

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Error al ejecutar las migraciones
    echo.
    echo Por favor verifica:
    echo   1. Que la base de datos este creada
    echo   2. Que las credenciales en .env sean correctas
    echo   3. Que el servidor MySQL este corriendo (si usas MySQL)
    echo.
    echo Puedes ejecutar las migraciones manualmente despues con:
    echo   php artisan migrate
    echo.
    pause
) else (
    echo [OK] Migraciones ejecutadas exitosamente
)

REM Clear cache
echo.
echo [7/7] Limpiando cache...
php artisan config:clear >nul 2>&1
php artisan cache:clear >nul 2>&1
echo [OK] Cache limpiado

echo.
echo ==========================================
echo   Instalacion Completada Exitosamente!
echo ==========================================
echo.
echo Proximos pasos:
echo.
echo 1. Inicia el servidor de desarrollo:
echo    php artisan serve
echo.
echo 2. Tu API estara disponible en:
echo    http://localhost:8000/api/products
echo.
echo 3. Prueba la API con los tests:
echo    php artisan test
echo.
echo 4. Importa la coleccion de Postman:
echo    Postman_Collection.json
echo.
echo Para mas informacion, consulta: README.md
echo.
pause
