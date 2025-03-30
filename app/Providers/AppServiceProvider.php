<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\Schema\Blueprint;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        //
    }

    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot()
    {
        // HTTPS zorlama (Production ortamında)
        if (env('APP_ENV') == 'production') {
            \URL::forceScheme('https');
        }
        
        // Sorunlu migrasyon veritabanından silinirse, tekrar çalıştırmaya çalışmayacak
        if (env('DB_CONNECTION') == 'sqlite' && Schema::hasTable('migrations')) {
            // Yinelenen migrasyon dosyasını migrations tablosundan kaldır
            DB::table('migrations')
                ->where('migration', 'like', '%2025_03_10_202007%')
                ->delete();
        }
    }
}
