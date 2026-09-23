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
        if (Schema::hasTable('tbl_users') && !Schema::hasColumn('tbl_users', 'state_agent')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                $table->unsignedBigInteger('state_agent')->nullable()->after('agent_id');
                $table->index('state_agent', 'idx_tbl_users_state_agent');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_users') && Schema::hasColumn('tbl_users', 'state_agent')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                $table->dropIndex('idx_tbl_users_state_agent');
                $table->dropColumn('state_agent');
            });
        }
    }
};

