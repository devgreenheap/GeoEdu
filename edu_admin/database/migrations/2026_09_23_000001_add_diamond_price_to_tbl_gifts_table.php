<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('tbl_gifts')) {
            return;
        }

        Schema::table('tbl_gifts', function (Blueprint $table) {
            if (!Schema::hasColumn('tbl_gifts', 'diamond_price')) {
                $table->integer('diamond_price')->default(0)->after('coin_price');
            }
        });

        // Backfill existing gifts so diamond_price matches coin_price
        if (Schema::hasColumn('tbl_gifts', 'diamond_price') && Schema::hasColumn('tbl_gifts', 'coin_price')) {
            DB::table('tbl_gifts')
                ->where(function ($query) {
                    $query->whereNull('diamond_price')
                        ->orWhere('diamond_price', 0);
                })
                ->whereNotNull('coin_price')
                ->update(['diamond_price' => DB::raw('coin_price')]);
        }
    }

    public function down(): void
    {
        if (!Schema::hasTable('tbl_gifts')) {
            return;
        }

        Schema::table('tbl_gifts', function (Blueprint $table) {
            if (Schema::hasColumn('tbl_gifts', 'diamond_price')) {
                $table->dropColumn('diamond_price');
            }
        });
    }
};
