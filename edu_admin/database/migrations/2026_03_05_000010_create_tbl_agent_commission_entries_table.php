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
        if (!Schema::hasTable('tbl_agent_commission_entries')) {
            Schema::create('tbl_agent_commission_entries', function (Blueprint $table) {
                $table->id();
                $table->integer('agent_id');
                $table->integer('user_id')->nullable();
                $table->integer('diamond_transaction_id')->nullable();
                $table->integer('diamond_pack_id')->nullable();
                $table->string('payment_id')->nullable();
                $table->decimal('purchase_amount', 14, 2)->default(0);
                $table->decimal('commission_percent', 8, 2)->default(0);
                $table->decimal('commission_amount', 14, 2)->default(0);
                $table->string('note')->nullable();
                $table->timestamps();

                $table->index('agent_id');
                $table->index('user_id');
                $table->index('diamond_transaction_id');
                $table->index('payment_id');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_agent_commission_entries')) {
            Schema::dropIfExists('tbl_agent_commission_entries');
        }
    }
};
