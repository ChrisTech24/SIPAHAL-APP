<?php

namespace App\Support;

use App\Models\Report;
use App\Models\User;

class SipahalFormatter
{
    public static function user(User $user): array
    {
        return [
            'uid' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone ?? '',
            'role' => $user->role ?? 'warga',
            'isActive' => (bool) ($user->is_active ?? true),
            'createdAt' => optional($user->created_at)->toIso8601String() ?? now()->toIso8601String(),
        ];
    }

    public static function report(Report $report): array
    {
        $history = $report->histories()
            ->orderBy('created_at')
            ->get()
            ->map(fn ($h) => [
                'id' => $h->id,
                'reportId' => $h->report_id,
                'fromStatus' => $h->from_status,
                'toStatus' => $h->to_status,
                'changedBy' => $h->changed_by,
                'changedByName' => $h->changed_by_name,
                'note' => $h->note,
                'createdAt' => optional($h->created_at)->toIso8601String() ?? now()->toIso8601String(),
            ])
            ->values()
            ->all();

        $assignment = is_string($report->assignment_json)
            ? json_decode($report->assignment_json, true)
            : $report->assignment_json;

        return [
            'id' => $report->id,
            'displayId' => $report->display_id,
            'reporterId' => $report->reporter_id,
            'reporterName' => $report->reporter_name,
            'locationText' => $report->location_text,
            'latitude' => (float) $report->latitude,
            'longitude' => (float) $report->longitude,
            'category' => $report->category,
            'description' => $report->description,
            'status' => $report->status,
            'rejectionReason' => $report->rejection_reason,
            'assignedOfficerId' => $report->assigned_officer_id,
            'assignedOfficerName' => $report->assigned_officer_name,
            'photoData' => $report->photo_data,
            'assignment' => $assignment,
            'history' => $history,
            'createdAt' => optional($report->created_at)->toIso8601String() ?? now()->toIso8601String(),
            'updatedAt' => optional($report->updated_at)->toIso8601String() ?? now()->toIso8601String(),
        ];
    }
}