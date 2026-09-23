<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('tbl_cities')) {
            Schema::create('tbl_cities', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('state_id');
                $table->unsignedBigInteger('country_id');
                $table->string('name', 150);
                $table->tinyInteger('status')->default(1);
                $table->timestamps();

                $table->index('state_id');
                $table->index('country_id');
                $table->unique(['state_id', 'name'], 'uniq_state_city_name');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('tbl_cities')) {
            Schema::dropIfExists('tbl_cities');
        }
    }
};
