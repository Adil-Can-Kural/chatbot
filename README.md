# Laravel Whatsapp Clone

### Example

![alt text](https://github.com/WailanTirajoh/laravel-whatsapp-web-clone/blob/main/ex.jpg?raw=true)

### Installation

- clone or fork this project
```
git clone https://github.com/WailanTirajoh/laravel-whatsapp-web-clone.git
```

- then copy .env from .env.example and configure it
```
cp .env.example .env
nano .env
```

- at this step you need to configure your database name, and pusher creds, but i already fill it with dummy test.
```
#install dependency
composer install
#install assets
npm install
```

- generate key and then run migration & seeder
```
php artisan key:generate
php artisan migrate:fresh --seed
```

- asset build
```
#for development
npm run dev
#for deployment
npm run build
```

- and then serve the apps
```
#to run websocket (terminal 1)
php artisan websockets:serve

#to run server (terminal 2)
php artisan serve
```

- You can login with
```
user 1
email: wailantirajoh@gmail.com
pass: wailan

user 2
email: putririnding21@gmail.com
pass: putri
```

or you can create your own account.

You can test this app on https://message.wailantirajoh.tech

## Render.com Deploy Talimatları

Bu proje artık Render.com'da kolayca deploy edilebilir.

### Ön Koşullar

- Bir Render.com hesabı
- Git deposuna erişim
- Render.com üzerinde bir PostgreSQL veritabanı

### PostgreSQL Veritabanı Bilgileri

Bu projede Render.com tarafından sağlanan PostgreSQL veritabanı kullanılmaktadır. Veritabanı bağlantı bilgileri aşağıdaki gibidir:

```
Hostname: dpg-cvkkl6l6ubrc73fq9b6g-a
Port: 5432
Database: chat_ake6
Username: chat_ake6_user
Internal Database URL: postgresql://chat_ake6_user:5mijBS3BEa5bXxFKj0DgF0cUsQOBLkGP@dpg-cvkkl6l6ubrc73fq9b6g-a/chat_ake6
External Database URL: postgresql://chat_ake6_user:5mijBS3BEa5bXxFKj0DgF0cUsQOBLkGP@dpg-cvkkl6l6ubrc73fq9b6g-a.frankfurt-postgres.render.com/chat_ake6
```

(Not: Şifre bilgisi güvenlik nedeniyle gizlenmiştir. Gerçek şifreyi kendi Render.com dashboard'unuzdan alabilirsiniz.)

### Deploy Adımları

1. Render.com hesabınıza giriş yapın
2. Dashboard üzerinden "New +" butonuna tıklayın ve "Web Service" seçeneğini seçin
3. Connect a repository bölümünde GitHub reponuzu bağlayın
4. Ayarları şu şekilde yapılandırın:
   - Name: whatsapp-web-clone (veya istediğiniz bir isim)
   - Environment: Docker
   - Branch: main (veya kullandığınız branch)
   - Root Directory: (boş bırakın)
5. "Create Web Service" butonuna tıklayın

Render.com, `render.yaml` dosyasını otomatik olarak algılayacak ve gerekli yapılandırmaları uygulayacaktır. Deployment tamamlandığında, uygulama URL'inize giderek uygulamayı kullanmaya başlayabilirsiniz.

### Notlar

- PostgreSQL veritabanı kullanıldığından, veritabanı verileriniz Render.com'un PostgreSQL servisi tarafından yönetilmektedir.
- WebSockets için pusher entegrasyonunun doğru yapılandırıldığından emin olun.
- Eğer hata alırsanız, Render.com dashboard'daki logları kontrol edin.
- Script dosyaları (build.sh ve start.sh) için gereken çalıştırma izinleri Dockerfile içinde otomatik olarak ayarlanacaktır.

## License

The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
