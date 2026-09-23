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
        if (!Schema::hasTable('tbl_gifter_return_wallets')) {
            Schema::create('tbl_gifter_return_wallets', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->unsignedBigInteger('gift_category_id')->default(0);
                $table->unsignedBigInteger('stars')->default(0);
                $table->timestamps();

                $table->unique(['user_id', 'gift_category_id'], 'uniq_gifter_return_user_category');
                $table->index('user_id', 'idx_gifter_return_user');
                $table->index('gift_category_id', 'idx_gifter_return_category');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_gifter_return_wallets')) {
            Schema::dropIfExists('tbl_gifter_return_wallets');
        }
    }
};

