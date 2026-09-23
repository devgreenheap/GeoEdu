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
        if (Schema::hasTable('tbl_manual_payouts') && !Schema::hasColumn('tbl_manual_payouts', 'transaction_id')) {
            Schema::table('tbl_manual_payouts', function (Blueprint $table) {
                $table->string('transaction_id')->nullable()->after('amount');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_manual_payouts') && Schema::hasColumn('tbl_manual_payouts', 'transaction_id')) {
            Schema::table('tbl_manual_payouts', function (Blueprint $table) {
                $table->dropColumn('transaction_id');
            });
        }
    }
};

