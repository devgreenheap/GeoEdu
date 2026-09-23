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
        if (Schema::hasTable('tbl_settings') && !Schema::hasColumn('tbl_settings', 'diamond_to_star_rate')) {
            Schema::table('tbl_settings', function (Blueprint $table) {
                $table->decimal('diamond_to_star_rate', 10, 2)->default(1)->after('coin_value');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_settings') && Schema::hasColumn('tbl_settings', 'diamond_to_star_rate')) {
            Schema::table('tbl_settings', function (Blueprint $table) {
                $table->dropColumn('diamond_to_star_rate');
            });
        }
    }
};

