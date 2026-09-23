<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('tbl_audio_room_history')) {
            return;
        }

        Schema::create('tbl_audio_room_history', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('host_id');
            $table->string('room_id', 191)->nullable();
            $table->string('room_name', 255)->nullable();
            $table->unsignedBigInteger('language_id')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->unsignedInteger('duration')->default(0);
            $table->unsignedInteger('peak_listener_count')->default(0);
            $table->tinyInteger('status')->default(1);
            $table->timestamps();

            $table->index(['host_id', 'status'], 'idx_audio_room_host_status');
            $table->index('ended_at', 'idx_audio_room_ended_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tbl_audio_room_history');
    }
};
