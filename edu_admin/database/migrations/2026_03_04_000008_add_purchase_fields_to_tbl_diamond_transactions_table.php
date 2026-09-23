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
        Schema::table('tbl_diamond_transactions', function (Blueprint $table) {
            if (!Schema::hasColumn('tbl_diamond_transactions', 'payment_id')) {
                $table->string('payment_id')->nullable()->after('note');
            }
            if (!Schema::hasColumn('tbl_diamond_transactions', 'order_id')) {
                $table->string('order_id')->nullable()->after('payment_id');
            }
            if (!Schema::hasColumn('tbl_diamond_transactions', 'signature')) {
                $table->string('signature')->nullable()->after('order_id');
            }
            if (!Schema::hasColumn('tbl_diamond_transactions', 'diamond_pack_id')) {
                $table->integer('diamond_pack_id')->nullable()->after('signature');
            }
            if (!Schema::hasColumn('tbl_diamond_transactions', 'amount')) {
                $table->decimal('amount', 12, 2)->nullable()->after('diamond_pack_id');
            }
            if (!Schema::hasColumn('tbl_diamond_transactions', 'status')) {
                $table->string('status')->nullable()->after('amount');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tbl_diamond_transactions', function (Blueprint $table) {
            if (Schema::hasColumn('tbl_diamond_transactions', 'status')) {
                $table->dropColumn('status');
            }
            if (Schema::hasColumn('tbl_diamond_transactions', 'amount')) {
                $table->dropColumn('amount');
            }
            if (Schema::hasColumn('tbl_diamond_transactions', 'diamond_pack_id')) {
                $table->dropColumn('diamond_pack_id');
            }
            if (Schema::hasColumn('tbl_diamond_transactions', 'signature')) {
                $table->dropColumn('signature');
            }
            if (Schema::hasColumn('tbl_diamond_transactions', 'order_id')) {
                $table->dropColumn('order_id');
            }
            if (Schema::hasColumn('tbl_diamond_transactions', 'payment_id')) {
                $table->dropColumn('payment_id');
            }
        });
    }
};
