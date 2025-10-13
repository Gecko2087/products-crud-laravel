<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Product;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;

class ProductApiTest extends TestCase
{
    use RefreshDatabase;

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
                 ])
                 ->assertJson([
                     'success' => true
                 ]);
    }

    public function test_obtener_productos_retorna_array_vacio_cuando_no_hay_productos()
    {
        $response = $this->getJson('/api/products');

        $response->assertStatus(200)
                 ->assertJson([
                     'success' => true,
                     'data' => [],
                     'message' => 'Productos obtenidos correctamente.'
                 ]);
    }

    public function test_obtener_productos_puede_filtrar_por_estado()
    {
        Product::factory()->create(['status' => 'active']);
        Product::factory()->create(['status' => 'inactive']);

        $response = $this->getJson('/api/products?status=active');

        $response->assertStatus(200);
        $data = $response->json('data');
        
        $this->assertCount(1, $data);
        $this->assertEquals('active', $data[0]['status']);
    }

    public function test_puede_crear_producto_con_datos_validos()
    {
        $productData = [
            'name' => 'Producto Nuevo',
            'price' => 49.99,
            'stock' => 100,
            'status' => 'active'
        ];

        $response = $this->postJson('/api/products', $productData);

        $response->assertStatus(201)
                 ->assertJson([
                     'success' => true,
                     'message' => 'Producto creado correctamente.'
                 ]);

        $this->assertDatabaseHas('products', [
            'name' => 'Producto Nuevo',
            'price' => 49.99
        ]);
    }

    public function test_validacion_falla_al_crear_producto_con_datos_invalidos()
    {
        $response = $this->postJson('/api/products', [
            'name' => '',
            'price' => -10,
            'stock' => 'invalido',
            'status' => 'estado_invalido'
        ]);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['name', 'price', 'stock', 'status']);
    }

    public function test_puede_obtener_un_solo_producto()
    {
        $product = Product::factory()->create();

        $response = $this->getJson("/api/products/{$product->id}");

        $response->assertStatus(200)
                 ->assertJson([
                     'success' => true,
                     'data' => [
                         'id' => $product->id,
                         'name' => $product->name
                     ]
                 ]);
    }

    public function test_obtener_producto_inexistente_retorna_404()
    {
        $response = $this->getJson('/api/products/99999');

        $response->assertStatus(404)
                 ->assertJson([
                     'success' => false,
                     'message' => 'Producto no encontrado.'
                 ]);
    }

    public function test_puede_actualizar_producto()
    {
        $product = Product::factory()->create();

        $updateData = [
            'name' => 'Producto Actualizado',
            'price' => 79.99,
            'stock' => 50,
            'status' => 'inactive'
        ];

        $response = $this->putJson("/api/products/{$product->id}", $updateData);

        $response->assertStatus(200)
                 ->assertJson([
                     'success' => true,
                     'message' => 'Producto actualizado correctamente.'
                 ]);

        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'name' => 'Producto Actualizado',
            'price' => 79.99
        ]);
    }

    public function test_puede_eliminar_producto()
    {
        $product = Product::factory()->create();

        $response = $this->deleteJson("/api/products/{$product->id}");

        $response->assertStatus(200)
                 ->assertJson([
                     'success' => true,
                     'message' => 'Producto eliminado correctamente.'
                 ]);

        $this->assertDatabaseMissing('products', [
            'id' => $product->id
        ]);
    }

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
}
