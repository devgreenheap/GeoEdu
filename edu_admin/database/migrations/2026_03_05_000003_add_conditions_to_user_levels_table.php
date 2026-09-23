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
        if (Schema::hasTable('user_levels')) {
            Schema::table('user_levels', function (Blueprint $table) {
                if (!Schema::hasColumn('user_levels', 'live_comments_count')) {
                    $table->unsignedBigInteger('live_comments_count')->default(0)->after('level');
                }
                if (!Schema::hasColumn('user_levels', 'host_followers_count')) {
                    $table->unsignedBigInteger('host_followers_count')->default(0)->after('live_comments_count');
                }
                if (!Schema::hasColumn('user_levels', 'send_gifts_count')) {
                    $table->unsignedBigInteger('send_gifts_count')->default(0)->after('host_followers_count');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('user_levels')) {
            Schema::table('user_levels', function (Blueprint $table) {
                $dropColumns = [];
                if (Schema::hasColumn('user_levels', 'live_comments_count')) {
                    $dropColumns[] = 'live_comments_count';
                }
                if (Schema::hasColumn('user_levels', 'host_followers_count')) {
                    $dropColumns[] = 'host_followers_count';
                }
                if (Schema::hasColumn('user_levels', 'send_gifts_count')) {
                    $dropColumns[] = 'send_gifts_count';
                }
                if (!empty($dropColumns)) {
                    $table->dropColumn($dropColumns);
                }
            });
        }
    }
};
