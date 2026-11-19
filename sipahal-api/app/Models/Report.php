<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Report extends Model
{
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'display_id',
        'reporter_id',
        'reporter_name',
        'location_text',
        'latitude',
        'longitude',
        'category',
        'description',
        'status',
        'rejection_reason',
        'assigned_officer_id',
        'assigned_officer_name',
        'photo_data',
        'assignment_json',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'float',
            'longitude' => 'float',
            'assignment_json' => 'array',
        ];
    }

    public function histories(): HasMany
    {
        return $this->hasMany(ReportHistory::class, 'report_id');
    }
}