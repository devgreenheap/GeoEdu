<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

foreach (\App\Models\Gifts::all() as $g) {
    echo "ID: {$g->id} | Title: {$g->title} | Image: {$g->image} | Anim: {$g->animation_url} | Sound: {$g->sound_url}\n";
}
