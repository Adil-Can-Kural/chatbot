<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('rooms', function (Blueprint $table) {
            if (!Schema::hasColumn('rooms', 'name')) {
                $table->string('name')->nullable()->after('type');
            }
            if (!Schema::hasColumn('rooms', 'is_bot')) {
                $table->boolean('is_bot')->default(false)->after('name');
            }
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('rooms', function (Blueprint $table) {
            if (Schema::hasColumn('rooms', 'name')) {
                $table->dropColumn('name');
            }
            if (Schema::hasColumn('rooms', 'is_bot')) {
                $table->dropColumn('is_bot');
            }
        });
    }
};
