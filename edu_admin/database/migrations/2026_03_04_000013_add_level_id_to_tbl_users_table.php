<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $hasLevelId = Schema::hasColumn('tbl_users', 'level_id');
        $foreignExists = collect(DB::select("
            SELECT CONSTRAINT_NAME
            FROM information_schema.KEY_COLUMN_USAGE
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'tbl_users'
              AND COLUMN_NAME = 'level_id'
              AND REFERENCED_TABLE_NAME IS NOT NULL
        "))->isNotEmpty();

        Schema::table('tbl_users', function (Blueprint $table) use ($foreignExists, $hasLevelId) {
            if ($foreignExists) {
                $table->dropForeign(['level_id']);
            }
            if ($hasLevelId) {
                $table->dropColumn('level_id');
            }
        });

        Schema::table('tbl_users', function (Blueprint $table) {
            $table->integer('level_id')->nullable()->after('language_id');
            $table->foreign('level_id')->references('id')->on('user_levels')->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $hasLevelId = Schema::hasColumn('tbl_users', 'level_id');
        $foreignExists = collect(DB::select("
            SELECT CONSTRAINT_NAME
            FROM information_schema.KEY_COLUMN_USAGE
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'tbl_users'
              AND COLUMN_NAME = 'level_id'
              AND REFERENCED_TABLE_NAME IS NOT NULL
        "))->isNotEmpty();

        Schema::table('tbl_users', function (Blueprint $table) use ($foreignExists, $hasLevelId) {
            if ($hasLevelId) {
                if ($foreignExists) {
                    $table->dropForeign(['level_id']);
                }
                $table->dropColumn('level_id');
            }
        });
    }
};
