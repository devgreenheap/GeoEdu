<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/// Gifts had only image/coin_price/category — no name and no dedicated
/// animation/sound, so every gift broadcast rendered as the generic text
/// "sent a Gift" with a single fixed sound regardless of which gift was
/// actually sent. This adds the real per-gift fields needed to fix that.
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('tbl_gifts')) {
            return;
        }
        Schema::table('tbl_gifts', function (Blueprint $table) {
            if (!Schema::hasColumn('tbl_gifts', 'title')) {
                $table->string('title', 100)->nullable()->after('id');
            }
            if (!Schema::hasColumn('tbl_gifts', 'animation_url')) {
                $table->string('animation_url')->nullable()->after('image');
            }
            if (!Schema::hasColumn('tbl_gifts', 'sound_url')) {
                $table->string('sound_url')->nullable()->after('animation_url');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('tbl_gifts')) {
            return;
        }
        Schema::table('tbl_gifts', function (Blueprint $table) {
            foreach (['title', 'animation_url', 'sound_url'] as $col) {
                if (Schema::hasColumn('tbl_gifts', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};
