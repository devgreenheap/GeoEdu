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
                if (!Schema::hasColumn('tbl_users', 'address1')) {
                    $table->string('address1', 255)->nullable()->after('country');
                }
                if (!Schema::hasColumn('tbl_users', 'address2')) {
                    $table->string('address2', 255)->nullable()->after('address1');
                }
                if (!Schema::hasColumn('tbl_users', 'city')) {
                    $table->string('city', 120)->nullable()->after('address2');
                }
                if (!Schema::hasColumn('tbl_users', 'state')) {
                    $table->string('state', 120)->nullable()->after('city');
                }
                if (!Schema::hasColumn('tbl_users', 'zipcode')) {
                    $table->string('zipcode', 30)->nullable()->after('state');
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('tbl_users')) {
            Schema::table('tbl_users', function (Blueprint $table) {
                $dropColumns = [];
                foreach (['address1', 'address2', 'city', 'state', 'zipcode'] as $column) {
                    if (Schema::hasColumn('tbl_users', $column)) {
                        $dropColumns[] = $column;
                    }
                }
                if (!empty($dropColumns)) {
                    $table->dropColumn($dropColumns);
                }
            });
        }
    }
};
