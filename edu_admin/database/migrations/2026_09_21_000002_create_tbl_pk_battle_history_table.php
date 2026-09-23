<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('tbl_pk_battle_history')) {
            return;
        }

        Schema::create('tbl_pk_battle_history', function (Blueprint $table) {
            $table->id();
            $table->string('mode', 20)->default('video');
            $table->unsignedBigInteger('user1_id');
            $table->unsignedBigInteger('user2_id');
            $table->unsignedBigInteger('user1_coins')->default(0);
            $table->unsignedBigInteger('user2_coins')->default(0);
            // null = draw. Always computed server-side from the coin totals.
            $table->unsignedBigInteger('winner_id')->nullable();
            $table->unsignedInteger('duration_minutes')->default(0);
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();

            $table->index('user1_id', 'idx_pk_user1');
            $table->index('user2_id', 'idx_pk_user2');
            $table->index('ended_at', 'idx_pk_ended_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tbl_pk_battle_history');
    }
};
