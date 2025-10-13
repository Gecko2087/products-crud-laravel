<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ProductController;

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::prefix('products')->group(function () {
    Route::get('/', [ProductController::class, 'index']);
    Route::post('/', [ProductController::class, 'store']);
    Route::get('/{id}', [ProductController::class, 'show']);
    Route::put('/{id}', [ProductController::class, 'update']);
    Route::delete('/{id}', [ProductController::class, 'destroy']);
});

// Endpoint de prueba para simular error 500 (solo disponible en modo desarrollo)
// IMPORTANTE: Solo está disponible cuando APP_DEBUG=true
// En producción (APP_DEBUG=false) este endpoint no estará disponible por seguridad.
if (config('app.debug')) {
    Route::get('/test/500', function () {
        return response()->json([
            'success' => false,
            'message' => 'Error simulado para pruebas de manejo de errores 500'
        ], 500);
    });
}
