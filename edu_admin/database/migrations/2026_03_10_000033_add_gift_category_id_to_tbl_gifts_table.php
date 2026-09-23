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
        if (Schema::hasTable('tbl_gifts') && !Schema::hasColumn('tbl_gifts', 'gift_category_id')) {
            Schema::table('tbl_gifts', function (Blueprint $table) {
                $table->unsignedBigInteger('gift_category_id')->nullable()->after('id');
                $table->index('gift_category_id', 'idx_tbl_gifts_gift_category_id');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_gifts') && Schema::hasColumn('tbl_gifts', 'gift_category_id')) {
            Schema::table('tbl_gifts', function (Blueprint $table) {
                $table->dropIndex('idx_tbl_gifts_gift_category_id');
                $table->dropColumn('gift_category_id');
            });
        }
    }
};

