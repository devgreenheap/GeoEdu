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
        if (Schema::hasTable('tbl_manual_payouts')) {
            Schema::table('tbl_manual_payouts', function (Blueprint $table) {
                if (!Schema::hasColumn('tbl_manual_payouts', 'paid_amount')) {
                    $table->decimal('paid_amount', 14, 2)->default(0)->after('amount');
                }
                if (!Schema::hasColumn('tbl_manual_payouts', 'commission_percent')) {
                    $table->decimal('commission_percent', 8, 2)->default(0)->after('paid_amount');
                }
                if (!Schema::hasColumn('tbl_manual_payouts', 'commission_amount')) {
                    $table->decimal('commission_amount', 14, 2)->default(0)->after('commission_percent');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_manual_payouts')) {
            Schema::table('tbl_manual_payouts', function (Blueprint $table) {
                $dropColumns = [];
                foreach (['paid_amount', 'commission_percent', 'commission_amount'] as $column) {
                    if (Schema::hasColumn('tbl_manual_payouts', $column)) {
                        $dropColumns[] = $column;
                    }
                }
                if (!empty($dropColumns)) {
                    $table->dropColumn($dropColumns);
                }
            });
        }
    }
};

