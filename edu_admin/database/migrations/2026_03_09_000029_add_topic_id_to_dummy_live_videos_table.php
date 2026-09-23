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
        if (Schema::hasTable('dummy_live_videos') && !Schema::hasColumn('dummy_live_videos', 'topic_id')) {
            Schema::table('dummy_live_videos', function (Blueprint $table) {
                $table->unsignedBigInteger('topic_id')->nullable()->after('sub_category_id');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('dummy_live_videos') && Schema::hasColumn('dummy_live_videos', 'topic_id')) {
            Schema::table('dummy_live_videos', function (Blueprint $table) {
                $table->dropColumn('topic_id');
            });
        }
    }
};

