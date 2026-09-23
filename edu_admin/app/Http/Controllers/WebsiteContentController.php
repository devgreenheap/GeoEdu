<?php

namespace App\Http\Controllers;

use App\Models\GlobalFunction;
use App\Models\HomeFeature;
use App\Models\HomeScreenshot;
use App\Models\SiteSetting;
use Illuminate\Http\Request;

class WebsiteContentController extends Controller
{
    /**
     * Admin page for managing the public website content.
     */
    public function index()
    {
        $setting = SiteSetting::current();
        $features = HomeFeature::orderBy('sort_order')->orderBy('id')->get();
        $screenshots = HomeScreenshot::orderBy('sort_order')->orderBy('id')->get();

        return view('websitePages', [
            'setting' => $setting,
            'features' => $features,
            'screenshots' => $screenshots,
        ]);
    }

    /**
     * Save Home page structured content (hero + section headings + store links).
     */
    public function saveHomeContent(Request $request)
    {
        $setting = SiteSetting::current();

        $setting->home_hero_title = $request->home_hero_title;
        $setting->home_hero_subtitle = $request->home_hero_subtitle;
        $setting->home_app_store_url = $request->home_app_store_url;
        $setting->home_play_store_url = $request->home_play_store_url;
        $setting->home_features_title = $request->home_features_title;
        $setting->home_features_subtitle = $request->home_features_subtitle;
        $setting->home_screenshots_title = $request->home_screenshots_title;
        $setting->home_screenshots_subtitle = $request->home_screenshots_subtitle;

        if ($request->hasFile('home_hero_image')) {
            if (!empty($setting->home_hero_image)) {
                GlobalFunction::deleteFile($setting->home_hero_image);
            }
            $setting->home_hero_image = GlobalFunction::saveFileAndGivePath($request->file('home_hero_image'));
        }

        $setting->save();

        return response()->json([
            'status' => true,
            'message' => 'Home page updated successfully.',
        ]);
    }

    /**
     * Save About Us rich-text content.
     */
    public function saveAboutContent(Request $request)
    {
        $setting = SiteSetting::current();
        $setting->about_us = $request->about_us;
        $setting->save();

        return response()->json([
            'status' => true,
            'message' => 'About Us updated successfully.',
        ]);
    }

    /**
     * Save Contact Us info.
     */
    public function saveContactContent(Request $request)
    {
        $setting = SiteSetting::current();
        $setting->contact_email = $request->contact_email;
        $setting->contact_phone = $request->contact_phone;
        $setting->contact_address = $request->contact_address;
        $setting->contact_facebook = $request->contact_facebook;
        $setting->contact_instagram = $request->contact_instagram;
        $setting->contact_twitter = $request->contact_twitter;
        $setting->contact_youtube = $request->contact_youtube;
        $setting->save();

        return response()->json([
            'status' => true,
            'message' => 'Contact Us updated successfully.',
        ]);
    }

    /* ----------------------------- Home Features ----------------------------- */

    public function listFeatures()
    {
        $features = HomeFeature::orderBy('sort_order')->orderBy('id')->get();

        return response()->json([
            'status' => true,
            'data' => $features,
        ]);
    }

    public function addFeature(Request $request)
    {
        if (empty(trim((string) $request->title))) {
            return response()->json([
                'status' => false,
                'message' => 'Title is required',
            ]);
        }

        $feature = new HomeFeature();
        $feature->icon = $request->icon;
        $feature->title = $request->title;
        $feature->description = $request->description;
        $feature->sort_order = (int) ($request->sort_order ?? 0);
        $feature->save();

        return response()->json([
            'status' => true,
            'message' => 'Feature added successfully',
        ]);
    }

    public function editFeature(Request $request)
    {
        $feature = HomeFeature::find($request->id);
        if (!$feature) {
            return response()->json([
                'status' => false,
                'message' => 'Feature not found',
            ]);
        }

        if (empty(trim((string) $request->title))) {
            return response()->json([
                'status' => false,
                'message' => 'Title is required',
            ]);
        }

        $feature->icon = $request->icon;
        $feature->title = $request->title;
        $feature->description = $request->description;
        $feature->sort_order = (int) ($request->sort_order ?? 0);
        $feature->save();

        return response()->json([
            'status' => true,
            'message' => 'Feature updated successfully',
        ]);
    }

    public function deleteFeature(Request $request)
    {
        $feature = HomeFeature::find($request->id);
        if (!$feature) {
            return response()->json([
                'status' => false,
                'message' => 'Feature not found',
            ]);
        }

        $feature->delete();

        return response()->json([
            'status' => true,
            'message' => 'Feature deleted successfully',
        ]);
    }

    /* --------------------------- Home Screenshots --------------------------- */

    public function listScreenshots()
    {
        $screenshots = HomeScreenshot::orderBy('sort_order')->orderBy('id')->get()
            ->map(function ($item) {
                $item->image_url = GlobalFunction::generateFileUrl($item->image);
                return $item;
            });

        return response()->json([
            'status' => true,
            'data' => $screenshots,
        ]);
    }

    public function addScreenshot(Request $request)
    {
        if (!$request->hasFile('image')) {
            return response()->json([
                'status' => false,
                'message' => 'Image is required',
            ]);
        }

        $screenshot = new HomeScreenshot();
        $screenshot->image = GlobalFunction::saveFileAndGivePath($request->file('image'));
        $screenshot->sort_order = (int) ($request->sort_order ?? 0);
        $screenshot->save();

        return response()->json([
            'status' => true,
            'message' => 'Screenshot added successfully',
        ]);
    }

    public function deleteScreenshot(Request $request)
    {
        $screenshot = HomeScreenshot::find($request->id);
        if (!$screenshot) {
            return response()->json([
                'status' => false,
                'message' => 'Screenshot not found',
            ]);
        }

        if (!empty($screenshot->image)) {
            GlobalFunction::deleteFile($screenshot->image);
        }
        $screenshot->delete();

        return response()->json([
            'status' => true,
            'message' => 'Screenshot deleted successfully',
        ]);
    }
}
