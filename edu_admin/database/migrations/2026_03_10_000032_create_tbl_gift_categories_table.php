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
        if (!Schema::hasTable('tbl_gift_categories')) {
            Schema::create('tbl_gift_categories', function (Blueprint $table) {
                $table->id();
                $table->string('name');
                $table->text('image')->nullable();
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_gift_categories')) {
            Schema::dropIfExists('tbl_gift_categories');
        }
    }
};

