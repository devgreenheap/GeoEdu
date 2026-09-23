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
                if (!Schema::hasColumn('tbl_users', 'category_name')) {
                    $table->string('category_name')->nullable()->after('category_id');
                }
                if (!Schema::hasColumn('tbl_users', 'sub_category_name')) {
                    $table->string('sub_category_name')->nullable()->after('sub_category_id');
                }
                if (!Schema::hasColumn('tbl_users', 'topic_name')) {
                    $table->string('topic_name')->nullable()->after('topic_id');
                }
                if (!Schema::hasColumn('tbl_users', 'language_name')) {
                    $table->string('language_name')->nullable()->after('language_id');
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
                foreach (['category_name', 'sub_category_name', 'topic_name', 'language_name'] as $column) {
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

