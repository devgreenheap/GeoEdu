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
        if (Schema::hasTable('tbl_settings')) {
            Schema::table('tbl_settings', function (Blueprint $table) {
                if (!Schema::hasColumn('tbl_settings', 'xp_comments_on_live')) {
                    $table->unsignedBigInteger('xp_comments_on_live')->default(0)->after('live_timeout');
                }
                if (!Schema::hasColumn('tbl_settings', 'xp_follow_host')) {
                    $table->unsignedBigInteger('xp_follow_host')->default(0)->after('xp_comments_on_live');
                }
                if (!Schema::hasColumn('tbl_settings', 'xp_send_gift_per_diamond')) {
                    $table->unsignedBigInteger('xp_send_gift_per_diamond')->default(0)->after('xp_follow_host');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_settings')) {
            Schema::table('tbl_settings', function (Blueprint $table) {
                $dropColumns = [];
                if (Schema::hasColumn('tbl_settings', 'xp_comments_on_live')) {
                    $dropColumns[] = 'xp_comments_on_live';
                }
                if (Schema::hasColumn('tbl_settings', 'xp_follow_host')) {
                    $dropColumns[] = 'xp_follow_host';
                }
                if (Schema::hasColumn('tbl_settings', 'xp_send_gift_per_diamond')) {
                    $dropColumns[] = 'xp_send_gift_per_diamond';
                }
                if (!empty($dropColumns)) {
                    $table->dropColumn($dropColumns);
                }
            });
        }
    }
};
