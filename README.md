# API REST CRUD de Productos

API REST para gestión de productos con Laravel 10. Incluye validación, manejo de errores y tests automatizados.

## Requisitos

- PHP 8.1+
- Composer
- MySQL 5.7+ / SQLite 3

## Tecnologías

- Laravel 10
- PHPUnit
- Eloquent ORM
- Form Request Validation

## Instalación Rápida

### Automática (recomendada)

```bash
# Windows
install.bat

# Linux / macOS
chmod +x install.sh
./install.sh
```

### Manual

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

## Configuración de Base de Datos

### MySQL

Edita `.env`:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=products_db
DB_USERNAME=root
DB_PASSWORD=
```

### SQLite (desarrollo)

```env
DB_CONNECTION=sqlite
```

```bash
touch database/database.sqlite
```

## Ejecutar Tests

```bash
php artisan test
```

Resultado esperado: 10 tests pasados

## Endpoints de la API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/products` | Listar productos |
| GET | `/api/products?status=active` | Filtrar por estado |
| GET | `/api/products?search=laptop` | Buscar por nombre |
| GET | `/api/products/{id}` | Ver un producto |
| POST | `/api/products` | Crear producto |
| PUT | `/api/products/{id}` | Actualizar producto |
| DELETE | `/api/products/{id}` | Eliminar producto |

## Ejemplos de Uso

### Crear producto

```bash
curl -X POST http://localhost:8000/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop Dell","price":1299.99,"stock":25,"status":"active"}'
```

### Listar productos

```bash
curl http://localhost:8000/api/products
```

### Postman

Importa el archivo `Postman_Collection.json` para probar todos los endpoints.

## Estructura de la Base de Datos

```sql
CREATE TABLE products (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);
```

## Validación

### Campos requeridos

- name: string, máximo 255 caracteres
- price: numérico, mínimo 0, máximo 2 decimales
- stock: entero, mínimo 0
- status: `active` o `inactive`

### Códigos de respuesta

- 200: Operación exitosa
- 201: Recurso creado
- 404: Recurso no encontrado
- 422: Error de validación
- 500: Error del servidor

## Testing

### Tests incluidos

El proyecto incluye 10 tests de características que verifican:

1. GET /api/products retorna JSON con estructura correcta
2. Lista vacía cuando no hay productos
3. Filtrado por estado funciona
4. Creación de producto con datos válidos
5. Validación rechaza datos inválidos
6. Obtención de producto por ID
7. Error 404 para productos inexistentes
8. Actualización de producto
9. Eliminación de producto
10. Simulación de error 500 por fallo de base de datos

### Ejemplo de test: verificar estructura JSON

```php
public function test_obtener_productos_retorna_json_con_estructura_esperada()
{
    Product::factory()->create([
        'name' => 'Producto de Prueba',
        'price' => 99.99,
        'stock' => 10,
        'status' => 'active'
    ]);

    $response = $this->getJson('/api/products');

    $response->assertStatus(200)
             ->assertJsonStructure([
                 'success',
                 'data' => [
                     '*' => [
                         'id',
                         'name',
                         'price',
                         'stock',
                         'status',
                         'created_at',
                         'updated_at'
                     ]
                 ],
                 'message'
             ]);
}
```

### Simulación de fallo de base de datos

```php
public function test_fallo_de_base_de_datos_retorna_error_500()
{
    // Simular fallo de base de datos cambiando la configuración a una BD inválida
    config(['database.connections.sqlite.database' => '/path/invalid/database.sqlite']);
    
    // Purgar la conexión para forzar reconexión con la configuración inválida
    DB::purge('sqlite');

    // Hacer petición al endpoint - debería fallar al intentar leer productos
    $response = $this->getJson('/api/products');

    // Verificar que retorna 500 con mensaje de error
    $response->assertStatus(500)
             ->assertJson([
                 'success' => false,
                 'message' => 'Error al obtener productos.'
             ]);
}
```

**Cómo funciona:**
1. Se cambia la configuración para apuntar a una ruta de base de datos inválida
2. Se purga la conexión para forzar reconexión con la nueva configuración
3. Se hace una petición a la API que intenta leer productos
4. La consulta falla porque la base de datos no existe
5. Se verifica que retorna error 500 con mensaje apropiado

**Probar este test específico:**
```bash
php artisan test --filter=test_fallo_de_base_de_datos_retorna_error_500
```

**Ver detalles del test:**
```bash
php artisan test --filter=test_fallo_de_base_de_datos_retorna_error_500 -v
```

### Diferencia entre tests y pruebas en Postman

**En PHPUnit (tests automatizados):**
- Se puede manipular la configuración de Laravel en tiempo de ejecución
- Se puede forzar fallos de base de datos sin afectar el entorno real
- Ideal para pruebas automatizadas y CI/CD

**En Postman (pruebas manuales):**
- No se puede manipular la configuración interna de Laravel
- Se hacen peticiones reales al servidor en ejecución
- Para simular errores se requiere manipular el entorno real

---

## Notas para Desarrolladores

### Endpoint de depuración de errores 500

Durante el desarrollo, existe un endpoint auxiliar para probar el manejo de errores:

**Endpoint:** `GET /api/test/500`

Este endpoint está protegido y **solo funciona cuando `APP_DEBUG=true`**. En producción retorna 404.

**Uso:**
```bash
# Windows PowerShell
curl.exe "http://localhost:8000/api/test/500" -H "Accept: application/json"

# Linux/Mac
curl http://localhost:8000/api/test/500 -H "Accept: application/json"
```

**⚠️ Importante:** Este endpoint es solo para desarrollo y debugging. No debe usarse en producción ni documentarse en APIs públicas.

---
