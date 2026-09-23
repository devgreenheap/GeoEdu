<?php

namespace App\Http\Controllers;

use App\Models\GlobalSettings;
use App\Models\HomeFeature;
use App\Models\HomeScreenshot;
use App\Models\SiteSetting;

class WebsiteController extends Controller
{
    private function appName(): string
    {
        return optional(GlobalSettings::first())->app_name ?: 'GeoEdu';
    }

    /**
     * Public marketing home page.
     */
    public function home()
    {
        $site = SiteSetting::current();
        $features = HomeFeature::orderBy('sort_order')->orderBy('id')->get();
        $screenshots = HomeScreenshot::orderBy('sort_order')->orderBy('id')->get();

        return view('web.home', [
            'site' => $site,
            'appName' => $this->appName(),
            'features' => $features,
            'screenshots' => $screenshots,
        ]);
    }

    /**
     * Public About Us page.
     */
    public function about()
    {
        return view('web.about', [
            'site' => SiteSetting::current(),
            'appName' => $this->appName(),
        ]);
    }

    /**
     * Public Contact Us page.
     */
    public function contact()
    {
        return view('web.contact', [
            'site' => SiteSetting::current(),
            'appName' => $this->appName(),
        ]);
    }
}
