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
        if (Schema::hasTable('level_badges') && !Schema::hasColumn('level_badges', 'image')) {
            Schema::table('level_badges', function (Blueprint $table) {
                $table->text('image')->nullable()->after('end_level');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('level_badges') && Schema::hasColumn('level_badges', 'image')) {
            Schema::table('level_badges', function (Blueprint $table) {
                $table->dropColumn('image');
            });
        }
    }
};
