<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ReportController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/register', [AuthController::class, 'register']);
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/officers', [AuthController::class, 'officers']);

    Route::get('/reports', [ReportController::class, 'index']);
    Route::post('/reports', [ReportController::class, 'store']);
    Route::post('/reports/upload', [ReportController::class, 'upload']);

    Route::patch('/reports/{id}/verify', [ReportController::class, 'verify']);
    Route::patch('/reports/{id}/reject', [ReportController::class, 'reject']);
    Route::patch('/reports/{id}/assign', [ReportController::class, 'assign']);
    Route::patch('/reports/{id}/start', [ReportController::class, 'start']);
    Route::patch('/reports/{id}/complete', [ReportController::class, 'complete']);
});