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
        if (Schema::hasTable('tbl_settings') && !Schema::hasColumn('tbl_settings', 'battle_duration_minutes')) {
            Schema::table('tbl_settings', function (Blueprint $table) {
                $table->integer('battle_duration_minutes')->default(1)->after('live_battle');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_settings') && Schema::hasColumn('tbl_settings', 'battle_duration_minutes')) {
            Schema::table('tbl_settings', function (Blueprint $table) {
                $table->dropColumn('battle_duration_minutes');
            });
        }
    }
};

