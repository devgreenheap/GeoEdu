<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('tbl_states') && !Schema::hasColumn('tbl_states', 'agent_id')) {
            Schema::table('tbl_states', function (Blueprint $table) {
                $table->unsignedBigInteger('agent_id')->nullable()->after('name');
                $table->index('agent_id', 'idx_tbl_states_agent_id');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('tbl_states') && Schema::hasColumn('tbl_states', 'agent_id')) {
            Schema::table('tbl_states', function (Blueprint $table) {
                $table->dropIndex('idx_tbl_states_agent_id');
                $table->dropColumn('agent_id');
            });
        }
    }
};
