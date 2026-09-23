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
        if (Schema::hasTable('tbl_settings') && !Schema::hasColumn('tbl_settings', 'admin_wallet')) {
            Schema::table('tbl_settings', function (Blueprint $table) {
                $table->unsignedBigInteger('admin_wallet')->default(0)->after('gifter_return');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_settings') && Schema::hasColumn('tbl_settings', 'admin_wallet')) {
            Schema::table('tbl_settings', function (Blueprint $table) {
                $table->dropColumn('admin_wallet');
            });
        }
    }
};

