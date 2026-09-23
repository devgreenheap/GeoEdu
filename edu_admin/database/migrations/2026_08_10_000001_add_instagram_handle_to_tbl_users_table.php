<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('tbl_users')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                if (!Schema::hasColumn('tbl_users', 'instagram_handle')) {
                    $table->string('instagram_handle', 100)->nullable()->after('bio');
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('tbl_users')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                if (Schema::hasColumn('tbl_users', 'instagram_handle')) {
                    $table->dropColumn('instagram_handle');
                }
            });
        }
    }
};
