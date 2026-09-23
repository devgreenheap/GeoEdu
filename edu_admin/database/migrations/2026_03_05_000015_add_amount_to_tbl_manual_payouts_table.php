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
        if (Schema::hasTable('tbl_manual_payouts') && !Schema::hasColumn('tbl_manual_payouts', 'amount')) {
            Schema::table('tbl_manual_payouts', function (Blueprint $table) {
                $table->decimal('amount', 14, 2)->default(0)->after('coins');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_manual_payouts') && Schema::hasColumn('tbl_manual_payouts', 'amount')) {
            Schema::table('tbl_manual_payouts', function (Blueprint $table) {
                $table->dropColumn('amount');
            });
        }
    }
};

