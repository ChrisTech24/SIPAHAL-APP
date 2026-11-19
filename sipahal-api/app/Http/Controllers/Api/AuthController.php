<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\SipahalFormatter;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', strtolower(trim($request->email)))->first();
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Email atau kata sandi salah.'], 401);
        }

        if (!($user->is_active ?? true)) {
            return response()->json(['message' => 'Akun ini sedang dinonaktifkan oleh admin.'], 403);
        }

        $token = $user->createToken('sipahal-mobile')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => SipahalFormatter::user($user),
        ]);
    }

    public function register(Request $request)
    {
        $request->validate([
            'name' => ['required', 'string', 'min:2', 'max:120'],
            'email' => ['required', 'email', 'unique:users,email'],
            'phone' => ['required', 'string', 'min:6', 'max:30'],
            'password' => ['required', 'string', 'min:6'],
        ]);

        $user = User::create([
            'id' => 'u-' . Str::uuid(),
            'name' => trim($request->name),
            'email' => strtolower(trim($request->email)),
            'phone' => trim($request->phone),
            'role' => 'warga',
            'is_active' => true,
            'password' => Hash::make($request->password),
        ]);

        $token = $user->createToken('sipahal-mobile')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => SipahalFormatter::user($user),
        ], 201);
    }

    public function me(Request $request)
    {
        $user = $request->user();
        if (!($user->is_active ?? true)) {
            return response()->json(['message' => 'Akun ini sedang dinonaktifkan oleh admin.'], 403);
        }

        return response()->json([
            'user' => SipahalFormatter::user($user),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()?->currentAccessToken()?->delete();
        return response()->json(['message' => 'Berhasil keluar.']);
    }

    public function officers()
    {
        $officers = User::where('role', 'petugas')
            ->where('is_active', true)
            ->orderBy('name')
            ->get()
            ->map(fn ($u) => SipahalFormatter::user($u))
            ->values();

        return response()->json(['data' => $officers]);
    }
}