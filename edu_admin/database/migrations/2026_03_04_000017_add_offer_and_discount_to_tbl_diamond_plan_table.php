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
        Schema::table('tbl_diamond_plan', function (Blueprint $table) {
            if (!Schema::hasColumn('tbl_diamond_plan', 'discounted_price')) {
                $table->decimal('discounted_price', 10, 2)->nullable()->after('diamond_plan_price');
            }
            if (!Schema::hasColumn('tbl_diamond_plan', 'offer_entry_effect_id')) {
                $table->unsignedBigInteger('offer_entry_effect_id')->nullable()->after('discounted_price');
                $table->foreign('offer_entry_effect_id')
                    ->references('id')
                    ->on('tbl_entry_effects')
                    ->nullOnDelete();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tbl_diamond_plan', function (Blueprint $table) {
            if (Schema::hasColumn('tbl_diamond_plan', 'offer_entry_effect_id')) {
                $table->dropForeign(['offer_entry_effect_id']);
                $table->dropColumn('offer_entry_effect_id');
            }
            if (Schema::hasColumn('tbl_diamond_plan', 'discounted_price')) {
                $table->dropColumn('discounted_price');
            }
        });
    }
};
