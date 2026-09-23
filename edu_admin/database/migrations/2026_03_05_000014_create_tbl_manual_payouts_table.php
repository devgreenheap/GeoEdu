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
        if (!Schema::hasTable('tbl_manual_payouts')) {
            Schema::create('tbl_manual_payouts', function (Blueprint $table) {
                $table->id();
                $table->integer('user_id');
                $table->integer('coins');
                $table->string('period_type', 20)->default('monthly');
                $table->text('note')->nullable();
                $table->timestamp('payout_date')->nullable();
                $table->timestamps();

                $table->index('user_id');
                $table->index('period_type');
                $table->index('payout_date');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_manual_payouts')) {
            Schema::dropIfExists('tbl_manual_payouts');
        }
    }
};

