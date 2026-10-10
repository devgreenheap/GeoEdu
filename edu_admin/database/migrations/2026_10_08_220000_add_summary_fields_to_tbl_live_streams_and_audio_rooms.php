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
        if (Schema::hasTable('tbl_live_streams')) {
            Schema::table('tbl_live_streams', function (Blueprint $table) {
                if (!Schema::hasColumn('tbl_live_streams', 'viewer_count')) {
                    $table->integer('viewer_count')->default(0)->after('duration');
                }
                if (!Schema::hasColumn('tbl_live_streams', 'followers_gained')) {
                    $table->integer('followers_gained')->default(0)->after('viewer_count');
                }
                if (!Schema::hasColumn('tbl_live_streams', 'stars_earned')) {
                    $table->integer('stars_earned')->default(0)->after('followers_gained');
                }
                if (!Schema::hasColumn('tbl_live_streams', 'total_comments')) {
                    $table->integer('total_comments')->default(0)->after('stars_earned');
                }
                if (!Schema::hasColumn('tbl_live_streams', 'total_gifts')) {
                    $table->integer('total_gifts')->default(0)->after('total_comments');
                }
            });
        }

        if (Schema::hasTable('tbl_audio_room_history')) {
            Schema::table('tbl_audio_room_history', function (Blueprint $table) {
                if (!Schema::hasColumn('tbl_audio_room_history', 'followers_gained')) {
                    $table->integer('followers_gained')->default(0)->after('peak_listener_count');
                }
                if (!Schema::hasColumn('tbl_audio_room_history', 'stars_earned')) {
                    $table->integer('stars_earned')->default(0)->after('followers_gained');
                }
                if (!Schema::hasColumn('tbl_audio_room_history', 'total_comments')) {
                    $table->integer('total_comments')->default(0)->after('stars_earned');
                }
                if (!Schema::hasColumn('tbl_audio_room_history', 'total_gifts')) {
                    $table->integer('total_gifts')->default(0)->after('total_comments');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_live_streams')) {
            Schema::table('tbl_live_streams', function (Blueprint $table) {
                $columns = ['viewer_count', 'followers_gained', 'stars_earned', 'total_comments', 'total_gifts'];
                foreach ($columns as $column) {
                    if (Schema::hasColumn('tbl_live_streams', $column)) {
                        $table->dropColumn($column);
                    }
                }
            });
        }

        if (Schema::hasTable('tbl_audio_room_history')) {
            Schema::table('tbl_audio_room_history', function (Blueprint $table) {
                $columns = ['followers_gained', 'stars_earned', 'total_comments', 'total_gifts'];
                foreach ($columns as $column) {
                    if (Schema::hasColumn('tbl_audio_room_history', $column)) {
                        $table->dropColumn($column);
                    }
                }
            });
        }
    }
};
