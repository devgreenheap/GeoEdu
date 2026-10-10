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
            if (!Schema::hasColumn('tbl_diamond_plan', 'product_id')) {
                $table->string('product_id', 50)->nullable()->after('id');
            }
            if (!Schema::hasColumn('tbl_diamond_plan', 'product_name')) {
                $table->string('product_name', 191)->nullable()->after('diamond_plan_price');
            }
            if (!Schema::hasColumn('tbl_diamond_plan', 'product_original_price')) {
                $table->decimal('product_original_price', 10, 2)->nullable()->after('product_name');
            }
            if (!Schema::hasColumn('tbl_diamond_plan', 'product_discounted_price')) {
                $table->decimal('product_discounted_price', 10, 2)->nullable()->after('product_original_price');
            }
        });

        Schema::table('tbl_settings', function (Blueprint $table) {
            if (!Schema::hasColumn('tbl_settings', 'silver_jewel_gst_percent')) {
                $table->decimal('silver_jewel_gst_percent', 5, 2)->nullable()->after('invoice_igst_percent');
            }
            if (!Schema::hasColumn('tbl_settings', 'making_charge_percent')) {
                $table->decimal('making_charge_percent', 5, 2)->nullable()->after('silver_jewel_gst_percent');
            }
            if (!Schema::hasColumn('tbl_settings', 'handling_fee')) {
                $table->decimal('handling_fee', 10, 2)->nullable()->default(0.00)->after('making_charge_percent');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tbl_diamond_plan', function (Blueprint $table) {
            if (Schema::hasColumn('tbl_diamond_plan', 'product_id')) {
                $table->dropColumn('product_id');
            }
            if (Schema::hasColumn('tbl_diamond_plan', 'product_name')) {
                $table->dropColumn('product_name');
            }
            if (Schema::hasColumn('tbl_diamond_plan', 'product_original_price')) {
                $table->dropColumn('product_original_price');
            }
            if (Schema::hasColumn('tbl_diamond_plan', 'product_discounted_price')) {
                $table->dropColumn('product_discounted_price');
            }
        });

        Schema::table('tbl_settings', function (Blueprint $table) {
            if (Schema::hasColumn('tbl_settings', 'silver_jewel_gst_percent')) {
                $table->dropColumn('silver_jewel_gst_percent');
            }
            if (Schema::hasColumn('tbl_settings', 'making_charge_percent')) {
                $table->dropColumn('making_charge_percent');
            }
            if (Schema::hasColumn('tbl_settings', 'handling_fee')) {
                $table->dropColumn('handling_fee');
            }
        });
    }
};
