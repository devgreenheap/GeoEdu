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
        if (Schema::hasTable('dummy_live_videos')) {
            Schema::table('dummy_live_videos', function (Blueprint $table) {
                if (!Schema::hasColumn('dummy_live_videos', 'category_id')) {
                    $table->unsignedBigInteger('category_id')->nullable()->after('user_id');
                }
                if (!Schema::hasColumn('dummy_live_videos', 'sub_category_id')) {
                    $table->unsignedBigInteger('sub_category_id')->nullable()->after('category_id');
                }
                if (!Schema::hasColumn('dummy_live_videos', 'language_id')) {
                    $table->unsignedBigInteger('language_id')->nullable()->after('sub_category_id');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('dummy_live_videos')) {
            Schema::table('dummy_live_videos', function (Blueprint $table) {
                $dropColumns = [];
                if (Schema::hasColumn('dummy_live_videos', 'language_id')) {
                    $dropColumns[] = 'language_id';
                }
                if (Schema::hasColumn('dummy_live_videos', 'sub_category_id')) {
                    $dropColumns[] = 'sub_category_id';
                }
                if (Schema::hasColumn('dummy_live_videos', 'category_id')) {
                    $dropColumns[] = 'category_id';
                }
                if (!empty($dropColumns)) {
                    $table->dropColumn($dropColumns);
                }
            });
        }
    }
};

