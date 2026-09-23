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
        if (!Schema::hasTable('level_badges')) {
            Schema::create('level_badges', function (Blueprint $table) {
                $table->id();
                $table->string('title');
                $table->unsignedInteger('start_level');
                $table->unsignedInteger('end_level');
                $table->timestamps();
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('level_badges')) {
            Schema::dropIfExists('level_badges');
        }
    }
};
