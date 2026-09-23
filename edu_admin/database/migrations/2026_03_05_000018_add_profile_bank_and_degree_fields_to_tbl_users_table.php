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
                if (!Schema::hasColumn('tbl_users', 'highest_degree')) {
                    $table->string('highest_degree')->nullable()->after('degree');
                }
                if (!Schema::hasColumn('tbl_users', 'bank_name')) {
                    $table->string('bank_name')->nullable()->after('highest_degree');
                }
                if (!Schema::hasColumn('tbl_users', 'account_number')) {
                    $table->string('account_number')->nullable()->after('bank_name');
                }
                if (!Schema::hasColumn('tbl_users', 'ifsc_code')) {
                    $table->string('ifsc_code')->nullable()->after('account_number');
                }
                if (!Schema::hasColumn('tbl_users', 'branch_name')) {
                    $table->string('branch_name')->nullable()->after('ifsc_code');
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
                $dropColumns = [];
                foreach (['highest_degree', 'bank_name', 'account_number', 'ifsc_code', 'branch_name'] as $column) {
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

