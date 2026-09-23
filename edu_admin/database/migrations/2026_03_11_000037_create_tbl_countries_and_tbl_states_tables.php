<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('tbl_countries')) {
            Schema::create('tbl_countries', function (Blueprint $table) {
                $table->id();
                $table->string('name', 150)->unique();
                $table->tinyInteger('status')->default(1);
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('tbl_states')) {
            Schema::create('tbl_states', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('country_id');
                $table->string('name', 150);
                $table->tinyInteger('status')->default(1);
                $table->timestamps();

                $table->index('country_id');
                $table->unique(['country_id', 'name'], 'uniq_country_state_name');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('tbl_states')) {
            Schema::dropIfExists('tbl_states');
        }
        if (Schema::hasTable('tbl_countries')) {
            Schema::dropIfExists('tbl_countries');
        }
    }
};
