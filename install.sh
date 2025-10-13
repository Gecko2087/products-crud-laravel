#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo " Products CRUD API - Instalación automática"
echo "=========================================="
echo

detect_os() {
  case "$(uname -s)" in
    Linux*) echo "Linux" ;;
    Darwin*) echo "macOS" ;;
    *) echo "Desconocido" ;;
  esac
}

echo "Sistema detectado: $(detect_os)"
echo

# Verificar PHP
if ! command -v php >/dev/null 2>&1; then
  echo "ERROR: PHP no está instalado. Instala PHP 8.1+ y vuelve a ejecutar."
  exit 1
fi
echo "[OK] PHP $(php -r 'echo PHP_VERSION;')"

# Verificar Composer
if ! command -v composer >/dev/null 2>&1; then
  echo "ERROR: Composer no está instalado. Descárgalo en https://getcomposer.org/download/"
  exit 1
fi
echo "[OK] Composer detectado"
echo

echo "[1/6] Instalando dependencias de Composer..."
composer install --no-interaction --prefer-dist --optimize-autoloader
echo "[OK] Dependencias instaladas"
echo

echo "[2/6] Creando directorios necesarios..."
mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs database
echo "[OK] Directorios listos"
echo

echo "[3/6] Configurando entorno (.env)..."
if [ ! -f .env ]; then
  cp .env.example .env
  echo "[OK] .env creado"
else
  echo "[OK] .env ya existe"
fi

echo "[4/6] Generando clave de aplicación..."
php artisan key:generate --no-interaction --force
echo "[OK] Clave generada"
echo

echo "[5/6] Configurando base de datos (SQLite por defecto)..."
# Forzar SQLite por defecto a menos que se pase --mysql
if [ "${1:-}" = "--mysql" ]; then
  read -rp "Host MySQL [127.0.0.1]: " DB_HOST; DB_HOST=${DB_HOST:-127.0.0.1}
  read -rp "Puerto MySQL [3306]: " DB_PORT; DB_PORT=${DB_PORT:-3306}
  read -rp "Base de datos [products_db]: " DB_DATABASE; DB_DATABASE=${DB_DATABASE:-products_db}
  read -rp "Usuario [root]: " DB_USERNAME; DB_USERNAME=${DB_USERNAME:-root}
  read -rsp "Contraseña (vacío si no tiene): " DB_PASSWORD; echo

  # Actualizar .env
  sed -i.bak "s/^DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env || true
  sed -i.bak "s/^DB_HOST=.*/DB_HOST=${DB_HOST}/" .env || true
  sed -i.bak "s/^DB_PORT=.*/DB_PORT=${DB_PORT}/" .env || true
  sed -i.bak "s/^DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" .env || true
  sed -i.bak "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" .env || true
  sed -i.bak "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" .env || true
  rm -f .env.bak
  echo "[OK] Configuración MySQL aplicada"
else
  # Configurar SQLite
  sed -i.bak "s/^DB_CONNECTION=.*/DB_CONNECTION=sqlite/" .env || true
  # Comentar otros campos si existen
  sed -i.bak "s/^DB_HOST=.*/# DB_HOST=127.0.0.1/" .env || true
  sed -i.bak "s/^DB_PORT=.*/# DB_PORT=3306/" .env || true
  sed -i.bak "s/^DB_DATABASE=.*/# DB_DATABASE=products_db/" .env || true
  sed -i.bak "s/^DB_USERNAME=.*/# DB_USERNAME=root/" .env || true
  sed -i.bak "s/^DB_PASSWORD=.*/# DB_PASSWORD=/" .env || true
  rm -f .env.bak
  touch database/database.sqlite
  echo "[OK] SQLite configurado"
fi

echo "[6/6] Ejecutando migraciones..."
php artisan migrate --force || {
  echo
  echo "[ERROR] Falló la ejecución de migraciones. Revisa las credenciales o crea la BD."
  exit 1
}
echo "[OK] Migraciones aplicadas"

echo
echo "Limpiando caché..."
php artisan config:clear >/dev/null 2>&1 || true
php artisan cache:clear >/dev/null 2>&1 || true
echo "[OK] Caché limpia"

echo
echo "Instalación completada. Próximos pasos:"
echo "  1) Inicia el servidor: php artisan serve"
echo "  2) API: http://localhost:8000/api/products"
echo "  3) Ejecuta tests: php artisan test"
echo "  4) Postman: importa Postman_Collection.json"
echo
