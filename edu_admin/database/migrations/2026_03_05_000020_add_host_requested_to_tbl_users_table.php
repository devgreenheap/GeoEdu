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
        if (Schema::hasTable('tbl_users') && !Schema::hasColumn('tbl_users', 'host_requested')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                $table->tinyInteger('host_requested')->default(0)->after('is_host');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_users') && Schema::hasColumn('tbl_users', 'host_requested')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                $table->dropColumn('host_requested');
            });
        }
    }
};

