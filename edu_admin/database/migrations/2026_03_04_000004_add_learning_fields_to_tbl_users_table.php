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
        Schema::table('tbl_users', function (Blueprint $table) {
            if (!Schema::hasColumn('tbl_users', 'category_id')) {
                $table->unsignedBigInteger('category_id')->nullable()->after('bio');
            }
            if (!Schema::hasColumn('tbl_users', 'sub_category_id')) {
                $table->unsignedBigInteger('sub_category_id')->nullable()->after('category_id');
            }
            if (!Schema::hasColumn('tbl_users', 'topic_id')) {
                $table->unsignedBigInteger('topic_id')->nullable()->after('sub_category_id');
            }
            if (!Schema::hasColumn('tbl_users', 'language_id')) {
                $table->unsignedBigInteger('language_id')->nullable()->after('topic_id');
            }
            if (!Schema::hasColumn('tbl_users', 'is_adult')) {
                $table->tinyInteger('is_adult')->default(0)->after('language_id');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tbl_users', function (Blueprint $table) {
            if (Schema::hasColumn('tbl_users', 'is_adult')) {
                $table->dropColumn('is_adult');
            }
            if (Schema::hasColumn('tbl_users', 'language_id')) {
                $table->dropColumn('language_id');
            }
            if (Schema::hasColumn('tbl_users', 'topic_id')) {
                $table->dropColumn('topic_id');
            }
            if (Schema::hasColumn('tbl_users', 'sub_category_id')) {
                $table->dropColumn('sub_category_id');
            }
            if (Schema::hasColumn('tbl_users', 'category_id')) {
                $table->dropColumn('category_id');
            }
        });
    }
};
