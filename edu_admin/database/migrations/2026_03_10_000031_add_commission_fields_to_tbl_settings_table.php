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
        if (Schema::hasTable('tbl_settings')) {
            Schema::table('tbl_settings', function (Blueprint $table) {
                if (!Schema::hasColumn('tbl_settings', 'host_commission')) {
                    $table->decimal('host_commission', 10, 2)->default(0)->after('diamond_to_star_rate');
                }
                if (!Schema::hasColumn('tbl_settings', 'admin_commision')) {
                    $table->decimal('admin_commision', 10, 2)->default(0)->after('host_commission');
                }
                if (!Schema::hasColumn('tbl_settings', 'agent_commision')) {
                    $table->decimal('agent_commision', 10, 2)->default(0)->after('admin_commision');
                }
                if (!Schema::hasColumn('tbl_settings', 'state_agent_commision')) {
                    $table->decimal('state_agent_commision', 10, 2)->default(0)->after('agent_commision');
                }
                if (!Schema::hasColumn('tbl_settings', 'gifter_return')) {
                    $table->decimal('gifter_return', 10, 2)->default(0)->after('state_agent_commision');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_settings')) {
            Schema::table('tbl_settings', function (Blueprint $table) {
                if (Schema::hasColumn('tbl_settings', 'gifter_return')) {
                    $table->dropColumn('gifter_return');
                }
                if (Schema::hasColumn('tbl_settings', 'state_agent_commision')) {
                    $table->dropColumn('state_agent_commision');
                }
                if (Schema::hasColumn('tbl_settings', 'agent_commision')) {
                    $table->dropColumn('agent_commision');
                }
                if (Schema::hasColumn('tbl_settings', 'admin_commision')) {
                    $table->dropColumn('admin_commision');
                }
                if (Schema::hasColumn('tbl_settings', 'host_commission')) {
                    $table->dropColumn('host_commission');
                }
            });
        }
    }
};

