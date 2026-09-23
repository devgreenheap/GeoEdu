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
        if (Schema::hasTable('user_levels') && Schema::hasColumn('user_levels', 'coins_collection')) {
            Schema::table('user_levels', function (Blueprint $table) {
                $table->dropColumn('coins_collection');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('user_levels') && !Schema::hasColumn('user_levels', 'coins_collection')) {
            Schema::table('user_levels', function (Blueprint $table) {
                $table->unsignedBigInteger('coins_collection')->default(0)->after('level');
            });
        }
    }
};
