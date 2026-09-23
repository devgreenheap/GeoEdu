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
        if (Schema::hasTable('tbl_settings') && !Schema::hasColumn('tbl_settings', 'agent_commission')) {
            Schema::table('tbl_settings', function (Blueprint $table) {
                $table->decimal('agent_commission', 10, 2)->default(0)->after('xp_send_gift_per_diamond');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_settings') && Schema::hasColumn('tbl_settings', 'agent_commission')) {
            Schema::table('tbl_settings', function (Blueprint $table) {
                $table->dropColumn('agent_commission');
            });
        }
    }
};
