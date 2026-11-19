<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ReportController extends Controller
{
    private function formatReport(object $row): array
    {
        $histories = DB::table('report_histories')
            ->where('report_id', $row->id)
            ->orderBy('created_at')
            ->get()
            ->map(function ($h) {
                return [
                    'id' => $h->id,
                    'reportId' => $h->report_id,
                    'fromStatus' => $h->from_status,
                    'toStatus' => $h->to_status,
                    'changedBy' => $h->changed_by,
                    'changedByName' => $h->changed_by_name,
                    'note' => $h->note,
                    'createdAt' => $h->created_at,
                ];
            })
            ->values();

        return [
            'id' => $row->id,
            'displayId' => $row->display_id ?? $row->id,
            'reporterId' => $row->reporter_id,
            'reporterName' => $row->reporter_name,
            'locationText' => $row->location_text,
            'latitude' => $row->latitude !== null ? (float) $row->latitude : null,
            'longitude' => $row->longitude !== null ? (float) $row->longitude : null,
            'category' => $row->category,
            'description' => $row->description,
            'status' => $row->status,
            'rejectionReason' => $row->rejection_reason,
            'assignedOfficerId' => $row->assigned_officer_id,
            'assignedOfficerName' => $row->assigned_officer_name,
            'photoData' => $row->photo_data,
            'assignment' => $row->assignment_json ? json_decode($row->assignment_json, true) : null,
            'createdAt' => $row->created_at,
            'updatedAt' => $row->updated_at,
            'history' => $histories,
            'histories' => $histories,
        ];
    }

    private function applyStatusChange(
        Request $request,
        string $id,
        string $defaultToStatus,
        string $defaultNote,
        string $successMessage,
        array $overrides = []
    ) {
        $report = DB::table('reports')->where('id', $id)->first();
        if (!$report) {
            return response()->json(['message' => 'Laporan tidak ditemukan'], 404);
        }

        $user = $request->user();
        $now = now();
        $fromStatus = $report->status;
        $toStatus = $overrides['status'] ?? $request->input('status', $defaultToStatus);

        $rejectionReason = $overrides['rejection_reason']
            ?? $request->input('rejectionReason')
            ?? $request->input('rejection_reason')
            ?? $request->input('reason')
            ?? $report->rejection_reason;

        $assignedOfficerId = $overrides['assigned_officer_id']
            ?? $request->input('assignedOfficerId')
            ?? $request->input('assigned_officer_id')
            ?? $report->assigned_officer_id;

        $assignedOfficerName = $overrides['assigned_officer_name']
            ?? $request->input('assignedOfficerName')
            ?? $request->input('assigned_officer_name')
            ?? $report->assigned_officer_name;

        if (array_key_exists('assignment_json', $overrides)) {
            $assignmentJson = $overrides['assignment_json'];
        } else {
            $assignment = $request->input('assignment');
            $assignmentJson = $assignment !== null ? json_encode($assignment) : $report->assignment_json;
        }

        DB::table('reports')->where('id', $id)->update([
            'status' => $toStatus,
            'rejection_reason' => $rejectionReason,
            'assigned_officer_id' => $assignedOfficerId,
            'assigned_officer_name' => $assignedOfficerName,
            'assignment_json' => $assignmentJson,
            'updated_at' => $now,
        ]);

        $note = $overrides['note'] ?? $request->input('note') ?? $defaultNote;

        DB::table('report_histories')->insert([
            'id' => 'hist-' . Str::lower(Str::random(8)),
            'report_id' => $id,
            'from_status' => $fromStatus,
            'to_status' => $toStatus,
            'changed_by' => $user?->id,
            'changed_by_name' => $user?->name ?? 'Sistem',
            'note' => $note,
            'created_at' => $now,
        ]);

        $updated = DB::table('reports')->where('id', $id)->first();

        return response()->json([
            'message' => $successMessage,
            'data' => $this->formatReport($updated),
        ]);
    }

    public function index(Request $request)
    {
        $query = DB::table('reports')->orderByDesc('created_at');

        if ($request->filled('status') && $request->status !== 'semua') {
            $query->where('status', $request->status);
        }

        if ($request->filled('category') && $request->category !== 'semua') {
            $query->where('category', $request->category);
        }

        $reports = $query->get()->map(fn ($row) => $this->formatReport($row))->values();

        return response()->json([
            'data' => $reports,
        ]);
    }

    public function store(Request $request)
    {
        $user = $request->user();
        $now = now();
        $id = 'rep-' . Str::lower(Str::random(8));
        $displayId = 'SPH-' . strtoupper(Str::random(6));

        $status = $request->input('status', 'menunggu');
        $locationText = $request->input('locationText') ?? $request->input('location_text') ?? '';
        $latitude = $request->input('latitude');
        $longitude = $request->input('longitude');
        $category = $request->input('category', 'Sampah rumah tangga');
        $description = $request->input('description', '');
        $photoData = $request->input('photoData') ?? $request->input('photo_data');

        DB::table('reports')->insert([
            'id' => $id,
            'display_id' => $displayId,
            'reporter_id' => $user?->id ?? $request->input('reporterId'),
            'reporter_name' => $user?->name ?? $request->input('reporterName') ?? 'Warga',
            'location_text' => $locationText,
            'latitude' => $latitude,
            'longitude' => $longitude,
            'category' => $category,
            'description' => $description,
            'status' => $status,
            'rejection_reason' => null,
            'assigned_officer_id' => null,
            'assigned_officer_name' => null,
            'photo_data' => $photoData,
            'assignment_json' => null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::table('report_histories')->insert([
            'id' => 'hist-' . Str::lower(Str::random(8)),
            'report_id' => $id,
            'from_status' => null,
            'to_status' => $status,
            'changed_by' => $user?->id,
            'changed_by_name' => $user?->name ?? 'Warga',
            'note' => 'Laporan dibuat',
            'created_at' => $now,
        ]);

        $created = DB::table('reports')->where('id', $id)->first();

        return response()->json([
            'message' => 'Laporan berhasil dikirim',
            'data' => $this->formatReport($created),
        ], 201);
    }

    public function verify(Request $request, string $id)
    {
        return $this->applyStatusChange(
            $request,
            $id,
            'terverifikasi',
            'Laporan diverifikasi oleh admin',
            'Laporan berhasil diverifikasi'
        );
    }

    public function reject(Request $request, string $id)
    {
        return $this->applyStatusChange(
            $request,
            $id,
            'ditolak',
            'Laporan ditolak oleh admin',
            'Laporan ditolak'
        );
    }

    public function assign(Request $request, string $id)
    {
        $officerId = $request->input('officerId')
            ?? $request->input('assignedOfficerId')
            ?? $request->input('officer_id');

        if (!$officerId) {
            return response()->json(['message' => 'ID petugas wajib diisi.'], 422);
        }

        $officer = DB::table('users')->where('id', $officerId)->first();
        if (!$officer) {
            return response()->json(['message' => 'Petugas tidak ditemukan.'], 404);
        }

        $admin = $request->user();
        $now = now()->toIso8601String();
        $officerName = $officer->name ?? 'Petugas';

        $assignmentPayload = [
            'id' => 'asg-' . Str::lower(Str::random(8)),
            'reportId' => $id,
            'officerId' => (string) $officer->id,
            'assignedBy' => (string) ($admin?->id ?? ''),
            'status' => 'ditugaskan',
            'assignedAt' => $now,
            'startedAt' => null,
            'completedAt' => null,
            'workNote' => null,
            'proofPhotoPath' => null,
        ];

        return $this->applyStatusChange(
            $request,
            $id,
            'ditugaskan',
            "Ditugaskan kepada {$officerName}",
            'Laporan berhasil ditugaskan',
            [
                'status' => 'ditugaskan',
                'assigned_officer_id' => (string) $officer->id,
                'assigned_officer_name' => $officerName,
                'assignment_json' => json_encode($assignmentPayload),
                'note' => "Ditugaskan kepada {$officerName}",
            ]
        );
    }

    public function start(Request $request, string $id)
    {
        $report = DB::table('reports')->where('id', $id)->first();
        if (!$report) {
            return response()->json(['message' => 'Laporan tidak ditemukan'], 404);
        }

        $user = $request->user();
        $now = now()->toIso8601String();
        $existing = $report->assignment_json ? json_decode($report->assignment_json, true) : [];

        $assignmentPayload = array_merge([
            'id' => 'asg-' . Str::lower(Str::random(8)),
            'reportId' => $id,
            'officerId' => (string) ($report->assigned_officer_id ?? $user?->id ?? ''),
            'assignedBy' => '',
            'assignedAt' => $now,
        ], $existing, [
            'status' => 'dikerjakan',
            'startedAt' => $now,
        ]);

        return $this->applyStatusChange(
            $request,
            $id,
            'dikerjakan',
            'Petugas mulai mengerjakan di lokasi',
            'Penugasan dimulai',
            [
                'status' => 'dikerjakan',
                'assignment_json' => json_encode($assignmentPayload),
                'note' => 'Petugas mulai mengerjakan di lokasi',
            ]
        );
    }

    public function complete(Request $request, string $id)
    {
        $report = DB::table('reports')->where('id', $id)->first();
        if (!$report) {
            return response()->json(['message' => 'Laporan tidak ditemukan'], 404);
        }

        $user = $request->user();
        $now = now()->toIso8601String();
        $workNote = trim((string) ($request->input('note') ?? ''));
        if ($workNote === '') {
            $workNote = 'Sampah sudah dibersihkan petugas';
        }
        $proofPath = $request->input('proofPhotoPath') ?? $request->input('proof_photo_path');

        $existing = $report->assignment_json ? json_decode($report->assignment_json, true) : [];

        $assignmentPayload = array_merge([
            'id' => 'asg-' . Str::lower(Str::random(8)),
            'reportId' => $id,
            'officerId' => (string) ($report->assigned_officer_id ?? $user?->id ?? ''),
            'assignedBy' => '',
            'assignedAt' => $now,
        ], $existing, [
            'status' => 'selesai',
            'completedAt' => $now,
            'workNote' => $workNote,
            'proofPhotoPath' => $proofPath,
        ]);

        return $this->applyStatusChange(
            $request,
            $id,
            'selesai',
            $workNote,
            'Penugasan selesai',
            [
                'status' => 'selesai',
                'assignment_json' => json_encode($assignmentPayload),
                'note' => $workNote,
            ]
        );
    }

    public function updateStatus(Request $request, string $id)
    {
        $report = DB::table('reports')->where('id', $id)->first();
        $fallbackStatus = $report?->status ?? 'menunggu';

        return $this->applyStatusChange(
            $request,
            $id,
            $fallbackStatus,
            'Status diubah menjadi ' . $request->input('status', $fallbackStatus),
            'Status laporan diperbarui'
        );
    }

    public function upload(Request $request)
    {
        if ($request->hasFile('photo')) {
            $file = $request->file('photo');
            $path = $file->store('reports', 'public');
            $url = asset('storage/' . $path);

            return response()->json([
                'message' => 'Foto berhasil diunggah',
                'path' => $path,
                'url' => $url,
                'data' => [
                    'path' => $path,
                    'url' => $url,
                ],
            ], 201);
        }

        if ($request->filled('photoData') || $request->filled('photo_data') || $request->filled('image')) {
            $raw = $request->input('photoData') ?? $request->input('photo_data') ?? $request->input('image');

            return response()->json([
                'message' => 'Foto diterima',
                'url' => $raw,
                'data' => [
                    'url' => $raw,
                ],
            ], 201);
        }

        return response()->json([
            'message' => 'Tidak ada file foto yang dikirim',
        ], 422);
    }
}