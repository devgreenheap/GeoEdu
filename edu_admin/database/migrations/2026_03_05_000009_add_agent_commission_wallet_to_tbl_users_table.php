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
        if (Schema::hasTable('tbl_users') && !Schema::hasColumn('tbl_users', 'agent_commission_wallet')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                $table->decimal('agent_commission_wallet', 14, 2)->default(0)->after('diamond_wallet');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_users') && Schema::hasColumn('tbl_users', 'agent_commission_wallet')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                $table->dropColumn('agent_commission_wallet');
            });
        }
    }
};
