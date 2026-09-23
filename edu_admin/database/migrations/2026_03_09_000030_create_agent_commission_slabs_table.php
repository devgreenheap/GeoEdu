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
        if (!Schema::hasTable('agent_commission_slabs')) {
            Schema::create('agent_commission_slabs', function (Blueprint $table) {
                $table->id();
                $table->unsignedInteger('start_level');
                $table->unsignedInteger('end_level');
                $table->decimal('commission_percent', 5, 2)->default(0);
                $table->timestamps();
                $table->index(['start_level', 'end_level'], 'idx_agent_commission_level_range');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('agent_commission_slabs')) {
            Schema::dropIfExists('agent_commission_slabs');
        }
    }
};

