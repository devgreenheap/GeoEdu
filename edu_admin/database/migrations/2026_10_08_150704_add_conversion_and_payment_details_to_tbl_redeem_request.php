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
        Schema::table('tbl_redeem_request', function (Blueprint $table) {
            $table->unsignedBigInteger('category_id')->default(0)->after('user_id');
            $table->string('category_name', 100)->default('All')->after('category_id');
            $table->string('payout_method', 50)->default('Bank Transfer')->after('gateway');
            $table->string('account_holder_name', 191)->nullable()->after('payout_method');
            $table->string('account_number', 100)->nullable()->after('account_holder_name');
            $table->string('ifsc_code', 50)->nullable()->after('account_number');
            $table->string('phone_number', 30)->nullable()->after('ifsc_code');
            $table->string('upi_number', 50)->nullable()->after('phone_number');
            $table->string('upi_id', 100)->nullable()->after('upi_number');
            $table->string('transaction_id', 191)->nullable()->after('status');
            $table->string('payment_date', 50)->nullable()->after('transaction_id');
            $table->string('payment_time', 50)->nullable()->after('payment_date');
            $table->decimal('paid_amount', 12, 2)->nullable()->after('payment_time');
            $table->text('admin_note')->nullable()->after('paid_amount');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tbl_redeem_request', function (Blueprint $table) {
            $table->dropColumn([
                'category_id',
                'category_name',
                'payout_method',
                'account_holder_name',
                'account_number',
                'ifsc_code',
                'phone_number',
                'upi_number',
                'upi_id',
                'transaction_id',
                'payment_date',
                'payment_time',
                'paid_amount',
                'admin_note',
            ]);
        });
    }
};
