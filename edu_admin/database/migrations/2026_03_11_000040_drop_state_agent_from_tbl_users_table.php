<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('tbl_users') && Schema::hasColumn('tbl_users', 'state_agent')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                try {
                    $table->dropIndex('idx_tbl_users_state_agent');
                } catch (\Throwable $e) {
                }
                $table->dropColumn('state_agent');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('tbl_users') && !Schema::hasColumn('tbl_users', 'state_agent')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                $table->unsignedBigInteger('state_agent')->nullable()->after('agent_id');
                $table->index('state_agent', 'idx_tbl_users_state_agent');
            });
        }
    }
};
