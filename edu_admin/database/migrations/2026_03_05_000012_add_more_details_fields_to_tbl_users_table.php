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
                if (!Schema::hasColumn('tbl_users', 'first_name')) {
                    $table->string('first_name')->nullable()->after('fullname');
                }
                if (!Schema::hasColumn('tbl_users', 'last_name')) {
                    $table->string('last_name')->nullable()->after('first_name');
                }
                if (!Schema::hasColumn('tbl_users', 'gender')) {
                    $table->string('gender', 30)->nullable()->after('last_name');
                }
                if (!Schema::hasColumn('tbl_users', 'date_of_birth')) {
                    $table->date('date_of_birth')->nullable()->after('gender');
                }
                if (!Schema::hasColumn('tbl_users', 'college_name')) {
                    $table->string('college_name')->nullable()->after('date_of_birth');
                }
                if (!Schema::hasColumn('tbl_users', 'degree')) {
                    $table->string('degree')->nullable()->after('college_name');
                }
                if (!Schema::hasColumn('tbl_users', 'full_qualification')) {
                    $table->string('full_qualification')->nullable()->after('degree');
                }
                if (!Schema::hasColumn('tbl_users', 'role')) {
                    $table->string('role')->nullable()->after('full_qualification');
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
                foreach ([
                    'first_name',
                    'last_name',
                    'gender',
                    'date_of_birth',
                    'college_name',
                    'degree',
                    'full_qualification',
                    'role',
                ] as $column) {
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

