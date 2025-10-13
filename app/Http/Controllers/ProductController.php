<?php

namespace App\Http\Controllers;

use App\Models\Product;
use App\Http\Requests\StoreProductRequest;
use App\Http\Requests\UpdateProductRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $query = Product::query();

            if ($request->filled('status')) {
                $query->where('status', $request->status);
            }

            if ($request->filled('search')) {
                $query->where('name', 'like', '%' . $request->search . '%');
            }

            $products = $query->orderBy('created_at', 'desc')->get();

            return $this->successResponse($products, 'Productos obtenidos correctamente.');
        } catch (\Exception $e) {
            return $this->errorResponse('Error al obtener productos.', $e->getMessage());
        }
    }

    public function store(StoreProductRequest $request): JsonResponse
    {
        try {
            $product = Product::create($request->validated());

            return $this->successResponse($product, 'Producto creado correctamente.', 201);
        } catch (\Exception $e) {
            return $this->errorResponse('Error al crear producto.', $e->getMessage());
        }
    }

    public function show(string $id): JsonResponse
    {
        $product = Product::find($id);

        if (!$product) {
            return $this->notFoundResponse('Producto no encontrado.');
        }

        return $this->successResponse($product, 'Producto obtenido correctamente.');
    }

    public function update(UpdateProductRequest $request, string $id): JsonResponse
    {
        $product = Product::find($id);

        if (!$product) {
            return $this->notFoundResponse('Producto no encontrado.');
        }

        try {
            $product->update($request->validated());

            return $this->successResponse($product->fresh(), 'Producto actualizado correctamente.');
        } catch (\Exception $e) {
            return $this->errorResponse('Error al actualizar producto.', $e->getMessage());
        }
    }

    public function destroy(string $id): JsonResponse
    {
        $product = Product::find($id);

        if (!$product) {
            return $this->notFoundResponse('Producto no encontrado.');
        }

        try {
            $product->delete();

            return $this->successResponse(null, 'Producto eliminado correctamente.');
        } catch (\Exception $e) {
            return $this->errorResponse('Error al eliminar producto.', $e->getMessage());
        }
    }

    private function successResponse($data, string $message, int $statusCode = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $data,
            'message' => $message
        ], $statusCode);
    }

    private function errorResponse(string $message, string $error = null): JsonResponse
    {
        $response = [
            'success' => false,
            'message' => $message
        ];

        if ($error && config('app.debug')) {
            $response['error'] = $error;
        }

        return response()->json($response, 500);
    }

    private function notFoundResponse(string $message): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message
        ], 404);
    }
}
