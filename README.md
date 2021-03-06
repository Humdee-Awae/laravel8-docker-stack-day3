# laravel8-docker-stack-day3
 
Laravel 8 React with Docker Script
==========================
----------------------------------------------
# Day 1
----------------------------------------------
ดูรายชื่อ images ใน docker
---
docker images

ดูรายการ container ที่สร้างไว้
---
docker ps  (มันจะแสดงแค่ตัวที่ start อยู่)
docker ps -a (แสดงทั้งหมดทั้่งตัวที่ start และ stop อยู่)

สร้าง container ใหม่
---
docker run ชื่อ image name หรือ image id
เช่น docker run hello-world

สั่ง start และ stop container
----
docker start ชื่อ container id หรือ container name
docker stop ชื่อ container id หรือ container name

สร้าง Dockerfile สำหรับไว้สร้าง Image ของเราเอง
---
FROM nginx:latest
COPY ./html /usr/share/nginx/html

คำสั่ง build image จาก dockerfile มาใช้งาน
---
docker build -t mynginx:1.0 .

คำสั่งในการ Run Image ที่เราสร้างขึ้นมา เป็น Container
---
docker run --name mywebapp -d -p 8800:80 mynginx:1.0

คำสั่งในการตรวจสอบว่า file docker-compose.yml เขียนถูกต้องหรือไม่
---
docker-compose config -q

ทำการสร้าง image และ container ให้เราด้วย docker-compose
---
docker-compose up -d

คำสั่งสำหรับเรียกสำหรับเรียกดูว่ามี service อะไรทำงานอยู่ใน docker-compose
---
docker-compose ps

สามารถสั่งหยุด service ทั้งหมดในไฟล์ compose โดย
---
docker-compose stop

เราสามารถที่จะลบทุกอย่างใน docker-compose ออกได้
---
docker-compose down

----------------------------------------------
# Day 2
----------------------------------------------
Step 1: กำหนดโครงสร้างโปรเจ็กต์ดังนี้
----
Workshop การสร้าง Custom Image Laravel 8
----
1.PHP + Laravel + NodeJS
2.MySQL
3.Nginx
4.Redis
5.MailHog
6.PHPMyAdmin
----
Laravel8DockerStack
   mysql
       |--data
   nginx
       |-- conf
            |-- app.conf
   redis
       |-- data
   src
       |-- ...
       |-- ...
   docker-compose.yaml
   Dockerfile

Step 2:  Clone ตัว Laravel 8 มาใส่ใน src
---
git clone https://github.com/laravel/laravel.git  -b 8.x src

Step 3: กำหนด Image ใน Dockerfile
---
# โหลด Base Image PHP 8.0.3
FROM php:8.0.3-fpm-buster

# ติดตั้ง Exention bcmath และ pdo_mysql
RUN docker-php-ext-install bcmath pdo_mysql

# สั่ง update image และ ติดตั้ง git zip และ unzip pacakage
RUN apt-get update
RUN apt-get install -y git zip unzip

# ติดตั้ง NodeJS
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - 
RUN apt-get install -y nodejs

# Copy file composer:latest ไว้ที่ /usr/bin/composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

EXPOSE 9000

หากต้องการรู้ว่าภายใน php:8.0.3-fpm-buster มี module อะไรอยู่บ้าง
--
docker run php:8.0.3-fpm-buster php -m


Step 4: กำหนดส่วนของ nginx setting
---
server {
    listen 80;
    index index.php index.html;
    error_log /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /var/www/public;
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
    location / {
        try_files $uri $uri/ /index.php?$query_string;
        gzip_static on;
    }
}

Step 5: กำหนดส่วนของ docker-compose.yaml
---
version: '3.9'

# Network for Laravel 8
networks:
  web_network:
    name: laravel8
    driver: bridge

services:

  # PHP App Service 
  app:
    build:
      context: .
      dockerfile: Dockerfile
    image: laravel8-app
    container_name: laravel8_app
    restart: always
    volumes:
      - ./src:/var/www
    networks:
      - web_network

  # MySQL Database Service
  db:
    image: mysql:8.0
    container_name: laravel8_mysql
    volumes:
      - ./mysql/data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=1234
      - MYSQL_DATABASE=laravel8db
      - MYSQL_USER=admin
      - MYSQL_PASSWORD=1234
    ports:
      - "3308:3306"
    restart: always
    networks:
      - web_network

  # Nginx Web Server Service
  nginx:
    image: nginx:1.19.8-alpine
    container_name: laravel8_nginx
    volumes:
      - ./src:/var/www
      - ./nginx/conf:/etc/nginx/conf.d
    ports:
      - "8100:80"
    restart: always
    networks:
      - web_network

เช็คความเรียบร้อยของ docker-compose
---
docker-compose config -q

Step 6: สั่ง docker-compose up -d
---
docker-compose up -d

ลองเช็คสถานะด้วยคำสั่ง
---
docker-compose ps

Step 7:  เรียกเข้าไปติดตั้ง library ของ laravel ใน service "app"
---
docker-compose exec app composer install

Step 8: เพิมไฟล์ .env โดยคัดลอกโค้ดทั้งหมดจาก .env.example มาใส่

Step 9: ทำการ Generate ตัว APP_KEY
--
docker-compose exec app php artisan key:generate

Step 10: Config Database ที่ไฟล์ .env
---
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel8db
DB_USERNAME=admin
DB_PASSWORD=1234

Step 11: ทำการ Run Migration (สร้างฐานและตารางให้อัตโมัติ)
---
เบื้องต้นให้ใช้คำสั่ง clear config ของไฟล์ .env
docker-compose exec app php artisan config:clear

คำสั่ง migrate database
---
docker-compose exec app php artisan migrate

Step 12: เพิ่ม Redis (caching) Service ใน docker-compose
---
  # Redis (caching)
  redis:
    image: redis:6.2.1-buster
    container_name: laravel8_redis
    volumes: 
      - ./redis/data:/data
    restart: always
    networks:
      - web_network  

Step 13: ทำการ down ตัว container ทั้งหมดไปก่อนแล้ว ทำการ docker-compose up -d
---
docker-compose down
docker-compose up -d

Step 14: ทำการติดตั้ง depency predis/predis ในโปรเจ็กต์ Laravel
--
docker-compose exec  app composer require predis/predis


Step 15: เพิ่ม mailhog Service ใน docker-compose.yml
---
  # MailHog (local mail testing)
  mailhog:
    image: mailhog/mailhog:v1.0.1
    container_name: laravel8_mailhog
    ports:
      - 8025:8025
    restart: always
    tty: true
    networks:
      - web_network

Step 16: เพิ่ม phpMyAdmin Service ใน docker-compose.yml
---
  # phpMyAdmin (MySQL managment)
  phpmyadmin:
    image: phpmyadmin:5.1.0-apache
    depends_on:
      - db
    container_name: laravel8_phpmyadmin
    environment:
      PMA_HOST: db
      PMA_PORT: 3306
      PMA_USER: admin
      PMA_PASSWORD: 1234
    ports:
      - 8200:80
    restart: always
    tty: true
    networks:
      - web_network

Step 17: ทำการ down ตัว container ทั้งหมดไปก่อนแล้ว ทำการ docker-compose up -d
---
docker-compose down
docker-compose up -d

docker-compose ps

Step 18: สร้าง Laravel Mail
---
docker-compose exec app php artisan make:mail TestMail

Step 19: เพิ่ม route
---
// Test Mailhog
Route::get('/send-email', function() {
    Mail::to('samit@itgeniussite.dev')->send(new TestMail);
});

Step 20: แก้ไฟล์ .env
---
MAIL_FROM_ADDRESS=samit@itgeniussite.dev

จากนั้นก็ clear cach
---
docker-compose exec app php artisan config:clear

----------------------------------------------
# Day 3
----------------------------------------------
-------------------
# Lavavel UI
-------------------
Step 1: ติดตั้ง Laravel UI package
---
docker-compose exec app composer require laravel/ui

Step 2: Generate auth scaffolding
---
docker-compose exec app php artisan ui vue --auth

Step 3: ติดตั้ง NPM Dependencies
---
docker-compose exec app npm i vue-loader

Step 4: ทำการ Compile และ Run แอพ
---
docker-compose exec app npm run watch

Step 5: ทดสอบเรียกหน้า login และ register
---
http://localhost:8100/login
http://localhost:8100/register

Step 6: ทดสอบ Reset Password
---
http://localhost:8100/password/reset

จากนั้นเรียกดูเมล์ได้ที่
http://localhost:8025/#

user: humdee.a@auct.co.th
pass: 12345678

Step 7: มาลองเปิดใช้งาน Verify อีเมล์ในหน้า Register
---
Laravel 8 มี Controller สำหรับ Verify อีเมล์มาให้แล้วอยู่ที่ app\Http\Controllers\Auth\VerificationController.php

จากนั้นไปที่ app\Http\Models\User.php ทำการ implements MustVerifyEmail เข้ามา
---
class User extends Authenticatable implements MustVerifyEmail
{
.
.
}

Step 8: เพิ่ม verify ใน Auth::routes() ที่ไฟล์ src\routes\web.php
---
// เปิดการ Verify Email
Auth::routes(['verify'=>true]);

Step 9: เพิ่ม verified ใน middleware ที่ไฟล์ src\app\Http\Controllers\HomeController.php
---
$this->middleware(['auth','verified']);

Step 10: ทดสอบ register และใช้งาน verify email ได้เลย
---
http://localhost:8100/register

-----------------------------------------
การสร้าง Rest API ใน Laravel 8
-----------------------------------------

Step 1: ลบฐานข้อมูลเดิมออกก่อน
---
docker-compose exec app php artisan migrate:rollback

Step 2: สร้าง migration resource conrtroller and model
---
docker-compose exec app php artisan make:model --migration --controller Product --api

Step 3: กำหนดโครงสร้าง migrations "create_users_table.php"
---
public function up()
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('fullname');
            $table->string('username');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->string('tel');
            $table->string('avatar')->nullable();
            $table->tinyInteger('role')->default(1);
            $table->rememberToken();
            $table->timestamps();
        });
    }

Step 4: กำหนดโครงสร้าง migrations "create_products_table.php"
---
public function up()
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug');
            $table->string('description')->nullable();
            $table->decimal('price',9, 2); // 2,859,893.50
            $table->string('image')->nullable();
            $table->unsignedBigInteger('user_id')->comment('Created By User');
            $table->foreign('user_id')->references('id')->on('users');
            $table->timestamps();
        });
    }

Step 5: ทำการ migrate ฐานข้อมูล
---
docker-compose exec app php artisan migrate

Step 6: เปิดใช้งาน Sanctum middleware ที่ไฟล์ src\app\Http\Kernel.php
---
        'api' => [
            \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
            'throttle:api',
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],

Step 7: แก้ไข User Model ที่ไฟล์ app/Models/User.php 
---
use Laravel\Sanctum\HasApiTokens;
use HasApiTokens, HasFactory, Notifiable;

protected $fillable = [
        'fullname',
        'username',
        'email',
        'email_verified_at',
        'password',
        'tel',
        'avatar',
        'role',
    ];

/**
     * Products Relationship
     */
    public function products()
    {
        return $this->hasMany(Product::class)->orderBy('id', 'desc');
    }

Step 8: แก้ไข Product Model ที่ไฟล์ app/Models/Product.php 
---
protected $fillable = [
        'name',
        'slug',
        'description',
        'price',
        'image',
        'user_id'
    ];

    /**
     * Relationship to Users
     */
    public function users(){

        // SELECT * 
        // FROM products
        // INNER JOIN users
        // ON products.user_id = users.id;

        return $this->belongsTo('App\Models\User','user_id')->select(['id','fullname','avatar']); 
    }


Step 9: แก้ไข Product Controller ที่ไฟล์ app/Http/Controllers/ProductController.php
---

// อ่านรายการสินค้าทั้งหมด
    public function index()
    {
        // Read all products
        return Product::all();
    }

/**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        // เช็คสิทธิ์ (role) ว่าเป็น admin (1) 
        $user = auth()->user();

        if($user->tokenCan("1")){

            // Validate form
            $request->validate([
                'name' => 'required|min:3',
                'slug' => 'required',
                'price' => 'required'
            ]);

            // กำหนดตัวแปรรับค่าจากฟอร์ม
            $data_product = array(
                'name' => $request->input('name'),
                'description' => $request->input('description'),
                'slug' => $request->input('slug'),
                'price' => $request->input('price'),
                'user_id' => $user->id
            );

            // Create data to tabale product
            return Product::create($data_product);

        }else{
            return [
                'status' => 'Permission denied to create'
            ];
        }
    }

    /**
     * Display the specified resource.
     *
     * @param  int $id
     * @return \Illuminate\Http\Response
     */
    public function show($id)
    {
        return Product::find($id);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int $id
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, $id)
    {
        // เช็คสิทธิ์ (role) ว่าเป็น admin (1) 
        $user = auth()->user();

        if($user->tokenCan("1")){
            
            $request->validate([
                'name' => 'required',
                'slug' => 'required',
                'price' => 'required'
            ]);

            $data_product = array(
                'name' => $request->input('name'),
                'description' => $request->input('description'),
                'slug' => $request->input('slug'),
                'price' => $request->input('price'),
                'user_id' => $user->id
            );

            $product = Product::find($id);
            $product->update($data_product);

            return $product;

        }else{
            return [
                'status' => 'Permission denied to create'
            ];
        }
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  int $id
     * @return \Illuminate\Http\Response
     */
    public function destroy($id)
    {
        
        // เช็คสิทธิ์ (role) ว่าเป็น admin (1) 
        $user = auth()->user();

        if($user->tokenCan("1")){
            return Product::destroy($id);
        }else{
            return [
                'status' => 'Permission denied to create'
            ];
        }

    }

Step 10: Protecting Routes ที่ไฟล์ \src\routes\api.php
---
use App\Http\Controllers\ProductController;

Route::group(['middleware' => 'auth:sanctum'], function(){
    Route::resource('products', ProductController::class);
});

จากนั้นทดสอบเรียก http://localhost:8100/api/products

จะพบว่าไม่สามารถ resume resouce นี้ได้ขึ้น
--
{
  "message": "Unauthenticated."
}

Step 11: สร้าง AuthController.php สำหรับไว้ทำ Register และ Login
---
docker-compose exec app php artisan make:controller AuthController --model=User

Step 12: สร้าง Method register และ login ใน src\app\Http\Controllers\AuthController.php
---

use Illuminate\Support\Facades\Hash;


// Register
    public function register(Request $request) {

        // Validate field
        $fields = $request->validate([
            'fullname' => 'required|string',
            'username' => 'required|string',
            'email'=> 'required|string|unique:users,email',
            'password'=>'required|string|confirmed',
            'tel'=>'required',
            'role'=> 'required|integer'
        ]);

        // Create user
        $user = User::create([
            'fullname' => $fields['fullname'],
            'username' => $fields['username'],
            'email' => $fields['email'],
            'password' => bcrypt($fields['password']), 
            'tel' => $fields['tel'],
            'role' => $fields['role']
        ]);

        // Create token
        $token = $user->createToken($request->userAgent(), ["$user->role"])->plainTextToken;

        $response = [
            'user' => $user,
            'token' => $token
        ];

        return response($response, 201);

    }

    // Login
    public function login(Request $request) {

        // Validate field
        $fields = $request->validate([
            'email'=> 'required|string',
            'password'=>'required|string'
        ]);

        // Check email
        $user = User::where('email', $fields['email'])->first();

        // Check password
        if(!$user || !Hash::check($fields['password'], $user->password)) {
            return response([
                'message' => 'Invalid login!'
            ], 401);
        }else{
            
            // ลบ token เก่าออกแล้วค่อยสร้างใหม่
            $user->tokens()->delete();

            // Create token
            $token = $user->createToken($request->userAgent(), ["$user->role"])->plainTextToken;
    
            $response = [
                'user' => $user,
                'token' => $token
            ];
    
            return response($response, 201);
        }

    }

    // Logout
    public function logout(Request $request){
        auth()->user()->tokens()->delete();
        return [
            'message' => 'Logged out'
        ];
    }


Step 13: แก้ไขไฟล์ src\routes\api.php เพิ่ม routes
---
use App\Http\Controllers\AuthController;


Route::post('register',[AuthController::class, 'register']);
Route::post('login',[AuthController::class, 'login']);

Route::group(['middleware' => 'auth:sanctum'], function(){
    Route::resource('products', ProductController::class);
    Route::post('logout',[AuthController::class, 'logout']);
});


Step 14: ทดสอบ Register และ Login/Logout API
---
http://localhost:8100/api/register

{
    "fullname":"John Doe",
    "username":"john",
    "email":"john@email.com",
    "password":"12345678",
    "password_confirmation":"12345678",
    "tel":"0881235678",
    "role":"1"
}

ผลลัพธ์ที่ควรได้กลับมา
---
{
  "user": {
    "fullname": "John Doe",
    "username": "john",
    "email": "john@email.com",
    "tel": "0881235678",
    "role": "1",
    "updated_at": "2022-02-23T10:39:57.000000Z",
    "created_at": "2022-02-23T10:39:57.000000Z",
    "id": 1
  },
  "token": "1|9cTmkOYJtLuNoBZp0enKbDV55uPWL1zKDdLmabOH"
}

การล็อกอิน
---
http://localhost:8100/api/login

{
    "email":"john@email.com",
    "password":"12345678"
}

ผลลัพธ์ที่ควรได้กลับมา
---
{
  "user": {
    "id": 1,
    "fullname": "John Doe",
    "username": "john",
    "email": "john@email.com",
    "email_verified_at": null,
    "tel": "0881235678",
    "avatar": null,
    "role": 1,
    "created_at": "2022-02-23T10:39:57.000000Z",
    "updated_at": "2022-02-23T10:39:57.000000Z"
  },
  "token": "2|quRW74msH7dPP48SAD4rnuPEZ8bNN5suZf9XXHnH"
}

Step 15: ทดสอบเรียกใช้ product api อีกครั้ง
---
http://localhost:8100/api/products

Auth Bearer
--
Bearer 2|quRW74msH7dPP48SAD4rnuPEZ8bNN5suZf9XXHnH

ผลลัพธ์ที่ควรได้กลับมา
---
Status: 200 OK


Step 15: ทดสอบเรียก API products
---
http://localhost:8100/api/products

Auth Bearer
--
Bearer 2|quRW74msH7dPP48SAD4rnuPEZ8bNN5suZf9XXHnH

HTTP Method: POST

Body:
{
    "name": "iPhone 12 Pro Max",
    "slug": "iphone-12-pro-max",
    "description": "iPhone 12 Pro Max detail",
    "price": "38500.00"
}

ผลลัพธ์ที่ควรได้กลับมา
---
Status: 200 OK


{
  "name": "iPhone 12 Pro Max",
  "description": "iPhone 12 Pro Max detail",
  "slug": "iphone-12-pro-max",
  "price": "38500.00",
  "user_id": 1,
  "updated_at": "2022-02-23T11:08:08.000000Z",
  "created_at": "2022-02-23T11:08:08.000000Z",
  "id": 1
}

Step 16: ทดสอบเรียก API products สำหรับการแก้ไข
---

http://localhost:8100/api/products/1

Auth Bearer
--
Bearer 2|quRW74msH7dPP48SAD4rnuPEZ8bNN5suZf9XXHnH

HTTP Method: PUT

Body:
{
    "name": "iPad Pro 2021",
    "slug": "ipad-pro-2021",
    "description": "iPad Pro 2021 detail",
    "price": "45000.00"
}

ผลลัพธ์ที่ควรได้กลับมา
---
Status: 200 OK


Step 16: ทดสอบเรียก API products สำหรับการลบ
---

http://localhost:8100/api/products/1

Auth Bearer
--
Bearer 2|quRW74msH7dPP48SAD4rnuPEZ8bNN5suZf9XXHnH

HTTP Method: DELETE

ผลลัพธ์ที่ควรได้กลับมา
---
Status: 200 OK
