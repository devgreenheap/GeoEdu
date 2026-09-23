<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('tbl_live_streams', 'video_url')) {
            Schema::table('tbl_live_streams', function (Blueprint $table) {
                $table->string('video_url', 500)->nullable()->after('duration');
            });
        }
        if (!Schema::hasColumn('tbl_live_streams', 'thumbnail')) {
            Schema::table('tbl_live_streams', function (Blueprint $table) {
                $table->string('thumbnail', 500)->nullable()->after('duration');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('tbl_live_streams', 'video_url')) {
            Schema::table('tbl_live_streams', function (Blueprint $table) {
                $table->dropColumn('video_url');
            });
        }
        if (Schema::hasColumn('tbl_live_streams', 'thumbnail')) {
            Schema::table('tbl_live_streams', function (Blueprint $table) {
                $table->dropColumn('thumbnail');
            });
        }
    }
};
