<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $accounts = [
            [
                'id' => 'u-warga',
                'name' => 'Ayu Lestari',
                'email' => 'warga@sipahal.com',
                'phone' => '0812-7000-1122',
                'role' => 'warga',
                'is_active' => true,
                'password' => Hash::make('warga123'),
            ],
            [
                'id' => 'u-petugas',
                'name' => 'Andri Saputra',
                'email' => 'petugas@sipahal.com',
                'phone' => '0813-5500-7788',
                'role' => 'petugas',
                'is_active' => true,
                'password' => Hash::make('petugas123'),
            ],
            [
                'id' => 'u-petugas-2',
                'name' => 'Rina Marlina',
                'email' => 'rina@sipahal.com',
                'phone' => '0813-5500-9900',
                'role' => 'petugas',
                'is_active' => true,
                'password' => Hash::make('petugas123'),
            ],
            [
                'id' => 'u-admin',
                'name' => 'Dewi Anggraini',
                'email' => 'admin@sipahal.com',
                'phone' => '0811-9000-5566',
                'role' => 'admin',
                'is_active' => true,
                'password' => Hash::make('admin123'),
            ],
        ];

        foreach ($accounts as $acc) {
            User::updateOrCreate(['email' => $acc['email']], $acc);
        }
    }
}