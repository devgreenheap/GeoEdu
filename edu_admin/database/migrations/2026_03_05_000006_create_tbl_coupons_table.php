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
        if (!Schema::hasTable('tbl_coupons')) {
            Schema::create('tbl_coupons', function (Blueprint $table) {
                $table->id();
                $table->string('coupon_code')->unique();
                $table->enum('discount_type', ['percentage', 'amount']);
                $table->decimal('discount_value', 10, 2)->default(0);
                $table->date('end_date')->nullable();
                $table->unsignedInteger('max_users')->nullable();
                $table->unsignedInteger('used_users')->default(0);
                $table->tinyInteger('status')->default(1);
                $table->timestamps();

                $table->index(['status', 'end_date']);
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tbl_coupons')) {
            Schema::dropIfExists('tbl_coupons');
        }
    }
};
