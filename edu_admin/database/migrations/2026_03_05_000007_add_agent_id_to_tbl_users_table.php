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
        if (Schema::hasTable('tbl_users') && !Schema::hasColumn('tbl_users', 'agent_id')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                $table->integer('agent_id')->nullable()->after('is_agent');
                $table->index('agent_id');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_users') && Schema::hasColumn('tbl_users', 'agent_id')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                $table->dropIndex(['agent_id']);
                $table->dropColumn('agent_id');
            });
        }
    }
};
