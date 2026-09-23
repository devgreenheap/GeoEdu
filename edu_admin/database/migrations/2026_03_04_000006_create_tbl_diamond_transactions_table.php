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
        Schema::create('tbl_diamond_transactions', function (Blueprint $table) {
            $table->id();
            $table->integer('user_id');
            $table->tinyInteger('type'); // 1=credit, 0=debit
            $table->unsignedBigInteger('diamonds');
            $table->unsignedBigInteger('balance_after')->default(0);
            $table->string('source')->nullable();
            $table->string('reference_type')->nullable();
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->text('note')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('tbl_users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tbl_diamond_transactions');
    }
};
