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
        if (Schema::hasTable('tbl_users')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                if (!Schema::hasColumn('tbl_users', 'refer_id')) {
                    $table->string('refer_id')->nullable()->after('agent_id');
                }
                if (!Schema::hasColumn('tbl_users', 'agent_id')) {
                    $table->unsignedBigInteger('agent_id')->nullable()->after('is_agent');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_users')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                if (Schema::hasColumn('tbl_users', 'refer_id')) {
                    $table->dropColumn('refer_id');
                }
            });
        }
    }
};

