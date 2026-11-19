<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reports', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->string('display_id')->nullable();
            $table->string('reporter_id')->nullable();
            $table->string('reporter_name')->nullable();
            $table->text('location_text')->nullable();
            $table->double('latitude')->nullable();
            $table->double('longitude')->nullable();
            $table->string('category')->nullable();
            $table->text('description')->nullable();
            $table->string('status')->default('menunggu');
            $table->text('rejection_reason')->nullable();
            $table->string('assigned_officer_id')->nullable();
            $table->string('assigned_officer_name')->nullable();
            $table->longText('photo_data')->nullable();
            $table->json('assignment_json')->nullable();
            $table->timestamps();
        });

        Schema::create('report_histories', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->string('report_id');
            $table->string('from_status')->nullable();
            $table->string('to_status');
            $table->string('changed_by')->nullable();
            $table->string('changed_by_name')->nullable();
            $table->text('note')->nullable();
            $table->timestamp('created_at')->nullable();

            $table->foreign('report_id')
                ->references('id')
                ->on('reports')
                ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_histories');
        Schema::dropIfExists('reports');
    }
};