<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tbl_favorite_users', function (Blueprint $table) {
            $table->id();
            $table->integer('from_user_id');
            $table->integer('to_user_id');
            $table->timestamps();

            $table->foreign('from_user_id')->references('id')->on('tbl_users')->onDelete('cascade');
            $table->foreign('to_user_id')->references('id')->on('tbl_users')->onDelete('cascade');
            $table->unique(['from_user_id', 'to_user_id'], 'uk_favorite_users_from_to');
            $table->index(['from_user_id'], 'idx_favorite_users_from');
            $table->index(['to_user_id'], 'idx_favorite_users_to');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_favorite_users');
    }
};
