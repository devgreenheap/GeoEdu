<?php

namespace App\Http\Controllers;

use App\Models\Admin;
use App\Models\AgentCommissionSlab;
use App\Models\Category;
use App\Models\City;
use App\Models\CoinPackages;
use App\Models\Categories;
use App\Models\Constants;
use App\Models\CountryMaster;
use App\Models\DeepARFilters;
use App\Models\DiamondBuyingInformation;
use App\Models\DummyLiveVideos;
use App\Models\Gifts;
use App\Models\GlobalFunction;
use App\Models\GlobalSettings;
use App\Models\Interest;
use App\Models\Language;
use App\Models\LevelBadges;
use App\Models\MusicCategories;
use App\Models\OnboardingScreens;
use App\Models\PaymentGateway;
use App\Models\RedeemGateways;
use App\Models\ReportReasons;
use App\Models\SubCategories;
use App\Models\StateMaster;
use App\Models\Topics;
use App\Models\UserLevels;
use App\Models\Users;
use Google\Client;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Session;

class SettingsController extends Controller
{
    public function levelDetails()
    {
        return view('levelDetails');
    }

    public function levels()
    {
        return view('levels');
    }

    public function xpPointsSettings()
    {
        $setting = GlobalSettings::first();
        return view('xpPointsSettings', compact('setting'));
    }

    public function agentSettings()
    {
        $setting = GlobalSettings::first();
        return view('agentSettings', compact('setting'));
    }

    public function agentCommissionSlabs()
    {
        return view('agentCommissionSlabs');
    }

    public function levelBadges()
    {
        return view('levelBadges');
    }

    public function androidDeepLinking(Request $request)
    {
        $request->validate([
            'sha_256' => 'required|array',
            'sha_256.*' => 'string', // each element must be a string
            'package_name' => 'required|string',
        ]);

        $filePath = public_path('assets/assetlinks.json');

        // Convert all values to uppercase
        $shaArray = array_map(function ($val) {
            return strtoupper(trim($val));
        }, $request->sha_256);

        // Build new JSON structure (overwrite everything)
        $data = [
            [
                "relation" => ["delegate_permission/common.handle_all_urls"],
                "target" => [
                    "namespace" => "android_app",
                    "package_name" => $request->package_name,
                    "sha256_cert_fingerprints" => $shaArray,
                ]
            ]
        ];

        // Save file (pretty JSON)
        File::put($filePath, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));

        return response()->json([
            'status' => true,
            'message' => 'assetlinks.json file replaced successfully',
            'data' => $data,
        ]);
    }

    public function iOSDeepLinking(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'team_id' => 'required|string',
            'package_name' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => $validator->errors()->first(),
            ]);
        }

        $teamId = strtoupper(trim($request->team_id)); // Ensure uppercase
        $packageName = trim($request->package_name);

        // Build AppID
        $appId = $teamId . '.' . $packageName;

        // Construct AASA structure
        $aasaData = [
            "applinks" => [
                "apps" => [],
                "details" => [
                    [
                        "appIDs" => [$appId],
                        "components" => [
                            [
                                "/" => "*",
                                "?" => ["\$web_only" => "true"],
                                "exclude" => true,
                                "comment" => "Exclude web_only links"
                            ],
                            [
                                "/" => "*",
                                "?" => ["%24web_only" => "true"],
                                "exclude" => true,
                                "comment" => "Exclude encoded web_only links"
                            ],
                            [
                                "/" => "/e/*",
                                "exclude" => true,
                                "comment" => "Exclude /e/* paths"
                            ],
                            [
                                "/" => "*",
                                "comment" => "Allow all other paths"
                            ],
                            [
                                "/" => "/",
                                "comment" => "Allow root path"
                            ]
                        ]
                    ]
                ]
            ],
            "webcredentials" => [
                "apps" => [$appId]
            ]
        ];

        // Save to root public folder (no extension for iOS)
        $filePath = public_path('assets/apple-app-site-association');
        File::put($filePath, json_encode($aasaData, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));

        return response()->json([
            'status' => true,
            'message' => 'iOS Deep Linking settings saved successfully.',
        ]);
    }

    function testingRoute(){
        $user = Users::find(17);
        GlobalFunction::deleteUserAccount($user);
    }

    function editUserLevel(Request $request){
        $item = UserLevels::find($request->id);
        if ($item == null) {
            return GlobalFunction::sendSimpleResponse(false, 'Level not found');
        }

        $level = trim((string) $request->level);
        if ($level === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Level is required');
        }

        $item->level = $level;
        $item->live_comments_count = intval($request->live_comments_count ?? 0);
        $item->host_followers_count = intval($request->host_followers_count ?? 0);
        $item->send_gifts_count = intval($request->send_gifts_count ?? 0);
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Item edited successfully!');
    }
    function addLevelBadge(Request $request){
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'start_level' => 'required|integer|min:1',
            'end_level' => 'required|integer|gte:start_level',
            'image' => 'required|image',
        ]);

        if ($validator->fails()) {
            return GlobalFunction::sendSimpleResponse(false, $validator->errors()->first());
        }

        $startLevel = (int) $request->start_level;
        $endLevel = (int) $request->end_level;

        $isOverlapping = LevelBadges::where(function ($query) use ($startLevel, $endLevel) {
            $query->whereBetween('start_level', [$startLevel, $endLevel])
                ->orWhereBetween('end_level', [$startLevel, $endLevel])
                ->orWhere(function ($q) use ($startLevel, $endLevel) {
                    $q->where('start_level', '<=', $startLevel)
                        ->where('end_level', '>=', $endLevel);
                });
        })->exists();

        if ($isOverlapping) {
            return GlobalFunction::sendSimpleResponse(false, 'Level range already exists');
        }

        $item = new LevelBadges();
        $item->title = $request->title;
        $item->start_level = $startLevel;
        $item->end_level = $endLevel;
        $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Item added successfully!');
    }
    function editLevelBadge(Request $request){
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:level_badges,id',
            'title' => 'required|string|max:255',
            'start_level' => 'required|integer|min:1',
            'end_level' => 'required|integer|gte:start_level',
            'image' => 'nullable|image',
        ]);

        if ($validator->fails()) {
            return GlobalFunction::sendSimpleResponse(false, $validator->errors()->first());
        }

        $startLevel = (int) $request->start_level;
        $endLevel = (int) $request->end_level;

        $isOverlapping = LevelBadges::where('id', '!=', $request->id)
            ->where(function ($query) use ($startLevel, $endLevel) {
                $query->whereBetween('start_level', [$startLevel, $endLevel])
                    ->orWhereBetween('end_level', [$startLevel, $endLevel])
                    ->orWhere(function ($q) use ($startLevel, $endLevel) {
                        $q->where('start_level', '<=', $startLevel)
                            ->where('end_level', '>=', $endLevel);
                    });
            })
            ->exists();

        if ($isOverlapping) {
            return GlobalFunction::sendSimpleResponse(false, 'Level range already exists');
        }

        $item = LevelBadges::find($request->id);
        $item->title = $request->title;
        $item->start_level = $startLevel;
        $item->end_level = $endLevel;
        if($request->has('image')){
            if($item->image != null){
                GlobalFunction::deleteFile($item->image);
            }
            $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        }
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Item edited successfully!');
    }
    function addUserLevel(Request $request){
        $level = trim((string) $request->level);
        if ($level === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Level is required');
        }

        $item = UserLevels::where('level', $level)->first();
        if($item != null){
            return GlobalFunction::sendSimpleResponse(false,'User level exists already');
        }
        $item = new UserLevels();
        $item->level = $level;
        $item->live_comments_count = intval($request->live_comments_count ?? 0);
        $item->host_followers_count = intval($request->host_followers_count ?? 0);
        $item->send_gifts_count = intval($request->send_gifts_count ?? 0);
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Item added successfully!');
    }
    function addWithdrawalGateway(Request $request){
        $item = new RedeemGateways();
        $item->title = $request->title;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Item added successfully!');
    }
    function editDeepARFilter(Request $request){
        $item = DeepARFilters::find($request->id);
        if ($item == null) {
            return GlobalFunction::sendSimpleResponse(false, 'DeepAR Filter not found');
        }

        $title = trim((string) ($request->title ?? ''));
        if ($title === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Title is required');
        }

        $item->title = $title;
        if($request->has('image')){
            $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        }
         if($request->has('filter_file')){
             $item->filter_file = GlobalFunction::saveFileAndGivePath($request->filter_file);
         }

        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Item edited successfully!');
    }
    function addDeepARFilter(Request $request){
        $title = trim((string) ($request->title ?? ''));
        if ($title === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Title is required');
        }

        $item = new DeepARFilters();
        $item->title = $title;
        $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        $item->filter_file = GlobalFunction::saveFileAndGivePath($request->filter_file);
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Item added successfully!');
    }
    function addReportReason(Request $request){
        $item = new ReportReasons();
        $item->title = $request->title;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Item added successfully!');
    }

    public function editWithdrawalGateway(Request $request){

        $item = RedeemGateways::where('id', $request->id)->first();
        $item->title = $request->title;
        $item->save();

        return response()->json([
            'status' => true,
            'message' => 'Item Updated Successfully',
        ]);
    }
    public function editReportReason(Request $request){

        $item = ReportReasons::where('id', $request->id)->first();
        $item->title = $request->title;
        $item->save();

        return response()->json([
            'status' => true,
            'message' => 'Item Updated Successfully',
        ]);
    }

    function deleteUserLevel(Request $request){
        $item = UserLevels::find($request->id);
        $item->delete();
        return GlobalFunction::sendSimpleResponse(true, 'Item deleted successfully');
    }
    function deleteLevelBadge(Request $request){
        $item = LevelBadges::find($request->id);
        if ($item == null) {
            return GlobalFunction::sendSimpleResponse(false, 'Item not found');
        }
        if ($item->image != null) {
            GlobalFunction::deleteFile($item->image);
        }
        $item->delete();
        return GlobalFunction::sendSimpleResponse(true, 'Item deleted successfully');
    }
    function deleteWithdrawalGateway(Request $request){
        $item = RedeemGateways::find($request->id);
        $item->delete();
        return GlobalFunction::sendSimpleResponse(true, 'Item deleted successfully');
    }
    function deleteDeepARFilter(Request $request){
        $item = DeepARFilters::find($request->id);
        GlobalFunction::deleteFile($item->image);
        GlobalFunction::deleteFile($item->filter_file);
        $item->delete();
        return GlobalFunction::sendSimpleResponse(true, 'Item deleted successfully');
    }
    function deleteReportReason(Request $request){
        $item = ReportReasons::find($request->id);
        $item->delete();
        return GlobalFunction::sendSimpleResponse(true, 'Item deleted successfully');
    }
    function deleteOnboardingScreen(Request $request){
        $item = OnboardingScreens::find($request->id);
        GlobalFunction::deleteFile($item->image);
        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'item deleted successfully');
    }
    function changeAndroidAdmobStatus($status){
        $settings = GlobalSettings::first();
        $settings->admob_android_status = $status;
        $settings->save();

        return GlobalFunction::sendSimpleResponse(true, 'Settings saved successfully!');
    }
    function changeiOSAdmobStatus($status){
        $settings = GlobalSettings::first();
        $settings->admob_ios_status = $status;
        $settings->save();

        return GlobalFunction::sendSimpleResponse(true, 'Settings saved successfully!');
    }


    public function updateOnboardingOrder(Request $request)
    {
        $items = OnboardingScreens::all();

        foreach ($items as $item) {
            $item->timestamps = false; // To disable update_at field updation
            $id = $item->id;

            foreach ($request->order as $order) {
                if ($order['id'] == $id) {
                    $item->position = $order['position'];
                    $item->save();
                }
            }
        }
         return response()->json(['status' => true, 'message'=> 'position updated successfully !']);
    }

    public function listDeepARFilters(Request $request)
    {
        $query = DeepARFilters::query();
        $totalData = $query->count();

        $columns = ['id'];
        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('title', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('id', 'DESC')
                        ->get();

        $data = $result->map(function ($item) {

            $imgUrl = GlobalFunction::generateFileUrl($item->image);
            $image = "<img class='rounded' width='80' height='80' src='{$imgUrl}' alt=''>";
            $fileUrl = GlobalFunction::generateFileUrl($item->filter_file);

            $file = "<a href='{$fileUrl}' target='_blank' download
                        class='btn border rounded-2 text-dark fs-6'>
                        <i class='me-2 uil-link'></i>
                        ". __('Filter File') ."
                        </a>";

            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-title='{$item->title}'
                        data-image='{$imgUrl}'
                        class='action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-pen'></i>
                        </a>";

            $delete = "<a href='#'
                          rel='{$item->id}'
                          class='action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                            <i class='uil-trash-alt'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";

            return [
                $image,
                $item->title,
                $file,
                $action
            ];
        });

        $json_data = [
            "draw" => intval($request->input('draw')),
            "recordsTotal" => intval($totalData),
            "recordsFiltered" => intval($totalFiltered),
            "data" => $data,
        ];

        return response()->json($json_data);
    }
    public function listReportReasons(Request $request)
    {
        $query = ReportReasons::query();
        $totalData = $query->count();

        $columns = ['id'];
        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('title', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('id', 'DESC')
                        ->get();

        $data = $result->map(function ($item) {

            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-title='{$item->title}'
                        class='action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-pen'></i>
                        </a>";

            $delete = "<a href='#'
                          rel='{$item->id}'
                          class='action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                            <i class='uil-trash-alt'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";

            return [
                $item->title,
                $action
            ];
        });

        $json_data = [
            "draw" => intval($request->input('draw')),
            "recordsTotal" => intval($totalData),
            "recordsFiltered" => intval($totalFiltered),
            "data" => $data,
        ];

        return response()->json($json_data);
    }
    public function listWithdrawalGateways(Request $request)
    {
        $query = RedeemGateways::query();
        $totalData = $query->count();

        $columns = ['id'];
        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('title', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('id', 'DESC')
                        ->get();

        $data = $result->map(function ($item) {

            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-title='{$item->title}'
                        class='action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-pen'></i>
                        </a>";

            $delete = "<a href='#'
                          rel='{$item->id}'
                          class='action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                            <i class='uil-trash-alt'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";

            return [
                $item->title,
                $action
            ];
        });

        $json_data = [
            "draw" => intval($request->input('draw')),
            "recordsTotal" => intval($totalData),
            "recordsFiltered" => intval($totalFiltered),
            "data" => $data,
        ];

        return response()->json($json_data);
    }
    public function listUserLevels(Request $request)
    {
        $query = UserLevels::query();
        $totalData = $query->count();
        $includeXpRequired = intval($request->input('include_xp_required') ?? 0) === 1;
        $settings = GlobalSettings::first();
        $xpCommentsOnLive = intval($settings->xp_comments_on_live ?? 0);
        $xpFollowHost = intval($settings->xp_follow_host ?? 0);
        $xpSendGiftPerDiamond = intval($settings->xp_send_gift_per_diamond ?? 0);

        $columns = ['id'];
        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');
        $levelFilter = trim((string) $request->input('level_filter', ''));

        if ($levelFilter !== '') {
            $query->where('level', 'LIKE', "%{$levelFilter}%");
        }

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('live_comments_count', 'LIKE', "%{$searchValue}%")
                    ->orWhere('host_followers_count', 'LIKE', "%{$searchValue}%")
                    ->orWhere('send_gifts_count', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('level', 'ASC')
                        ->get();

        $data = $result->map(function ($item) use ($includeXpRequired, $xpCommentsOnLive, $xpFollowHost, $xpSendGiftPerDiamond) {
            $liveCommentsCount = intval($item->live_comments_count ?? 0);
            $hostFollowersCount = intval($item->host_followers_count ?? 0);
            $sendGiftsCount = intval($item->send_gifts_count ?? 0);
            $xpRequiredToNextLevel = ($liveCommentsCount * $xpCommentsOnLive)
                + ($hostFollowersCount * $xpFollowHost)
                + ($sendGiftsCount * $xpSendGiftPerDiamond);

            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-level='{$item->level}'
                        data-livecommentscount='{$item->live_comments_count}'
                        data-hostfollowerscount='{$item->host_followers_count}'
                        data-sendgiftscount='{$item->send_gifts_count}'
                        class='action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-pen'></i>
                        </a>";

            $delete = "<a href='#'
                          rel='{$item->id}'
                          class='action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                            <i class='uil-trash-alt'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";

            $row = [
                $item->level,
                $liveCommentsCount,
                $hostFollowersCount,
                $sendGiftsCount,
            ];

            if ($includeXpRequired) {
                $row[] = $xpRequiredToNextLevel;
            }

            $row[] = $action;

            return $row;
        });

        $json_data = [
            "draw" => intval($request->input('draw')),
            "recordsTotal" => intval($totalData),
            "recordsFiltered" => intval($totalFiltered),
            "data" => $data,
        ];

        return response()->json($json_data);
    }
    public function listLevelBadges(Request $request)
    {
        $query = LevelBadges::query();
        $totalData = $query->count();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('title', 'LIKE', "%{$searchValue}%")
                    ->orWhere('start_level', 'LIKE', "%{$searchValue}%")
                    ->orWhere('end_level', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
            ->limit($limit)
            ->orderBy('start_level', 'ASC')
            ->get();

        $data = $result->map(function ($item) {
            $imgUrl = GlobalFunction::generateFileUrl($item->image);
            $image = "<img class='rounded border' width='56' height='56' src='{$imgUrl}' alt=''>";

            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-title='{$item->title}'
                        data-startlevel='{$item->start_level}'
                        data-endlevel='{$item->end_level}'
                        data-image='{$imgUrl}'
                        class='action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-pen'></i>
                        </a>";

            $delete = "<a href='#'
                          rel='{$item->id}'
                          class='action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                            <i class='uil-trash-alt'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";

            return [
                $image,
                $item->title,
                $item->start_level,
                $item->end_level,
                $action
            ];
        });

        $json_data = [
            "draw" => intval($request->input('draw')),
            "recordsTotal" => intval($totalData),
            "recordsFiltered" => intval($totalFiltered),
            "data" => $data,
        ];

        return response()->json($json_data);
    }


    public function onboardingScreensList(Request $request)
    {
        $query = OnboardingScreens::query();
        $totalData = $query->count();

        $columns = ['id'];
        // $limit = $request->input('length');
        // $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('title', 'LIKE', "%{$searchValue}%")
                ->orWhere('description','LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->orderBy('position', 'ASC')
                        // ->limit($limit)
                        // ->offset($start)
                        ->get();

        $data = $result->map(function ($item) {


            $imgUrl = GlobalFunction::generateFileUrl($item->image);
            $image = "<img class='rounded border' width='80' height='80' src='{$imgUrl}' alt=''>";

            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-title='{$item->title}'
                        data-description='{$item->description}'
                        data-image='{$imgUrl}'
                        class='action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-pen'></i>
                        </a>";

            $delete = "<a href='#'
                          rel='{$item->id}'
                          class='action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                            <i class='uil-trash-alt'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";

            $title = '<span class="text-dark font-weight-bold font-16">' . $item->title . '</span><br>';
            $desc = '<span>' . $item->description . '</span>';
            $detail = $title . $desc;

            $sortable = '<div data-id='.$item->id.' class="sort-handler grabbable action-btn  d-flex align-items-center justify-content-center border rounded-2 text-info">
                <i class="uil-direction"></i>
            </div>';

            return [
                $sortable,
                $item->position,
                $image,
                $detail,
                $action
            ];
        });

        $json_data = [
            "draw" => intval($request->input('draw')),
            "recordsTotal" => intval($totalData),
            "recordsFiltered" => intval($totalFiltered),
            "data" => $data,
        ];

        return response()->json($json_data);
    }

    public function updateOnboardingScreen(Request $request){

        $item = OnboardingScreens::where('id', $request->id)->first();
        if ($item == null) {
            return GlobalFunction::sendSimpleResponse(false, 'Onboarding item not found');
        }

        $title = trim((string) ($request->title ?? ''));
        $description = trim((string) ($request->description ?? ''));
        if ($title === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Title is required');
        }
        if ($description === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Description is required');
        }

        $item->title = $title;
        $item->description = $description;
        if($request->has('image')){
            if($item->image != null){
                GlobalFunction::deleteFile($item->image);
            }
            $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        }
        $item->save();

        return response()->json([
            'status' => true,
            'message' => 'Item Updated Successfully',
        ]);
    }

    public function addOnBoardingScreen(Request $request){
        $title = trim((string) ($request->title ?? ''));
        $description = trim((string) ($request->description ?? ''));
        if ($title === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Title is required');
        }
        if ($description === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Description is required');
        }

        $item = new OnboardingScreens();
        $item->title = $title;
        $item->description = $description;
        $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        $item->position = OnboardingScreens::max('position')+1;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Onboarding Added successfully');
    }

    public function settings()
    {
        $setting = GlobalSettings::first();
        $baseUrl = GlobalFunction::getItemBaseUrl();
        $userType = Session::get('user_type');

         // Default values
        $packageName = '';
        $sha256 = '';
        $iosAppId = '';
        $iosPackageName = '';
        $iosTeamId = '';

         // --------------------
        // Android assetlinks.json
        // --------------------
        $assetFilePath = public_path('assets/assetlinks.json');
        if (File::exists($assetFilePath)) {
            $jsonContent = File::get($assetFilePath);
            $data = json_decode($jsonContent, true);

            if (!empty($data) && isset($data[0]['target'])) {
                $packageName = $data[0]['target']['package_name'] ?? '';
                $sha256 = isset($data[0]['target']['sha256_cert_fingerprints'])
                    ? implode(',', $data[0]['target']['sha256_cert_fingerprints'])
                    : '';
            }
        }

        // --------------------
        // iOS apple-app-site-association
        // --------------------
        $aasaFilePath = public_path('assets/apple-app-site-association');
        if (File::exists($aasaFilePath)) {
            $jsonContent = File::get($aasaFilePath);
            $data = json_decode($jsonContent, true);

            if (!empty($data) && isset($data['applinks']['details'][0]['appIDs'][0])) {

                $appId = $data['applinks']['details'][0]['appIDs'][0];
                $iosAppId = $appId;

                // Split into Team ID + Package Name
                $parts = explode('.', $appId, 2);
                if (count($parts) === 2) {
                    $iosTeamId = $parts[0];
                    $iosPackageName = $parts[1];
                }
            }
        }



        return view('settings', [
            'setting'=>$setting,
            'baseUrl'=>$baseUrl,
            'userType'=>$userType,
            'packageName' => $packageName,
            'sha256' => $sha256,
            'iosAppId' => $iosAppId,
            'iosPackageName' => $iosPackageName,
            'iosTeamId' => $iosTeamId

        ]);
    }



    public function fetchSettings()
    {
        $data = GlobalSettings::first();
        $languages = Language::all();
        $diamondToStarRate = floatval($data->diamond_to_star_rate ?? 1);
        if ($diamondToStarRate <= 0) {
            $diamondToStarRate = 1;
        }
        $gifts = Gifts::leftJoin('tbl_gift_categories as gc', 'gc.id', '=', 'tbl_gifts.gift_category_id')
            ->select('tbl_gifts.*', 'gc.name as category_name')
            ->orderBy('tbl_gifts.gift_category_id', 'ASC')
            ->orderBy('tbl_gifts.coin_price', 'DESC')
            ->get()
            ->map(function ($gift) use ($diamondToStarRate) {
                $gift->category_id = !is_null($gift->gift_category_id) ? intval($gift->gift_category_id) : null;
                $giftDiamondPrice = intval($gift->diamond_price ?? 0);
                $gift->diamond_price = $giftDiamondPrice > 0
                    ? $giftDiamondPrice
                    : intval(ceil(intval($gift->coin_price ?? 0) / $diamondToStarRate));
                $gift->image = !empty($gift->image) ? (GlobalFunction::generateFileUrl($gift->image) ?: $gift->image) : null;
                $gift->animation_url = !empty($gift->animation_url) ? (GlobalFunction::generateFileUrl($gift->animation_url) ?: $gift->animation_url) : null;
                $gift->sound_url = !empty($gift->sound_url) ? (GlobalFunction::generateFileUrl($gift->sound_url) ?: $gift->sound_url) : null;
                return $gift;
            })
            ->values();
        $diamondBuyingInformation = DiamondBuyingInformation::orderBy('id', 'ASC')->get();
        $onBoarding = OnboardingScreens::all();
        $redeemGateways = RedeemGateways::all();
        $reportReasons = ReportReasons::all();
        $deepARFilters = DeepARFilters::all();
        $dummyLives = DummyLiveVideos::where('status', 1)->with(['user:'.Constants::userPublicFields])->get();
        $userLevels = UserLevels::all();
        $musicCategories = MusicCategories::where('is_deleted', 0)->withCount('musics')->get();
        $itemBaseUrl = GlobalFunction::getItemBaseUrl();

        $data->battle_duration_minutes = intval($data->battle_duration_minutes ?? 1);
        $data->itemBaseUrl = $itemBaseUrl;
        $data->languages = $languages;
        $data->onBoarding = $onBoarding;
        $data->redeemGateways = $redeemGateways;
        $data->reportReasons = $reportReasons;
        $data->deepARFilters = $deepARFilters;
        $data->gifts = $gifts;
        $data->diamond_buying_information = $diamondBuyingInformation;
        $data->musicCategories = $musicCategories;
        $data->userLevels = $userLevels;
        $data->dummyLives = $dummyLives;

        return response()->json([
            'status' => true,
            'message' => 'Settings Fetched',
            'data' => $data,
        ]);
    }

    public function fetchCategorySubCategoryTopic(Request $request)
    {
        $categoriesQuery = Categories::where('status', 1);
        if ($request->filled('category_id')) {
            $categoriesQuery->where('id', $request->category_id);
        }

        $categories = $categoriesQuery
            ->orderBy('name')
            ->get(['id', 'name']);

        $subCategoriesQuery = SubCategories::where('status', 1);
        if ($request->filled('category_id')) {
            $subCategoriesQuery->where('category_id', $request->category_id);
        }
        $subCategories = $subCategoriesQuery
            ->orderBy('name')
            ->get(['id', 'name', 'category_id']);

        $topicsQuery = Topics::where('status', 1);
        if ($request->filled('category_id')) {
            $topicsQuery->where('category_id', $request->category_id);
        }
        if ($request->filled('sub_category_id')) {
            $topicsQuery->where('sub_category_id', $request->sub_category_id);
        }
        $topics = $topicsQuery
            ->orderBy('name')
            ->get(['id', 'name', 'sub_category_id']);

        $topicsBySubCategory = $topics->groupBy('sub_category_id');

        $subCategoriesByCategory = $subCategories->groupBy('category_id')->map(function ($items) use ($topicsBySubCategory, $request) {
            return $items->filter(function ($subCategory) use ($topicsBySubCategory, $request) {
                if ($request->filled('sub_category_id')) {
                    return intval($subCategory->id) === intval($request->sub_category_id);
                }

                return true;
            })->map(function ($subCategory) use ($topicsBySubCategory) {
                return [
                    'id' => $subCategory->id,
                    'name' => $subCategory->name,
                    'category_id' => $subCategory->category_id,
                    'topics' => ($topicsBySubCategory[$subCategory->id] ?? collect())->values()->toArray(),
                ];
            })->values();
        });

        $data = $categories->map(function ($category) use ($subCategoriesByCategory) {
            return [
                'id' => $category->id,
                'name' => $category->name,
                'sub_categories' => ($subCategoriesByCategory[$category->id] ?? collect())->values()->toArray(),
            ];
        })->values();

        return GlobalFunction::sendDataResponse(true, 'Data fetched successfully', $data);
    }

    public function fetchLanguages()
    {
        $languages = Language::orderBy('id')->get();

        return GlobalFunction::sendDataResponse(true, 'Languages fetched successfully', $languages);
    }

    public function fetchInterests()
    {
        $interests = Interest::where('status', 1)->orderBy('name')->get(['id', 'name']);

        return GlobalFunction::sendDataResponse(true, 'Interests fetched successfully', $interests);
    }

    public function fetchCountryStateList(Request $request)
    {
        $countriesQuery = CountryMaster::query();
        if ($request->filled('country_id')) {
            $countriesQuery->where('id', intval($request->country_id));
        }

        $countries = $countriesQuery->orderBy('name')->get(['id', 'name']);
        $countryIds = $countries->pluck('id')->toArray();

        // Skip the (potentially large) states join when the caller only needs
        // the country list — e.g. the initial dropdown population. States are
        // then fetched lazily per-country via the `country_id` filter above.
        $includeStates = !$request->has('include_states') || $request->boolean('include_states');

        $states = $includeStates
            ? StateMaster::whereIn('country_id', $countryIds)
                ->orderBy('name')
                ->get(['id', 'country_id', 'name'])
                ->groupBy('country_id')
            : collect();

        $data = $countries->map(function ($country) use ($states) {
            return [
                'id' => intval($country->id),
                'name' => $country->name,
                'states' => ($states[$country->id] ?? collect())->map(function ($state) {
                    return [
                        'id' => intval($state->id),
                        'country_id' => intval($state->country_id),
                        'name' => $state->name,
                    ];
                })->values()->toArray(),
            ];
        })->values();

        return GlobalFunction::sendDataResponse(true, 'Country/state list fetched successfully', $data);
    }

    public function fetchCityList(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'state_id' => 'required|integer|exists:tbl_states,id',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $cities = City::where('state_id', intval($request->state_id))
            ->orderBy('name')
            ->get(['id', 'state_id', 'name']);

        return GlobalFunction::sendDataResponse(true, 'City list fetched successfully', $cities);
    }

    public function fetchLevelBadges()
    {
        $badges = LevelBadges::orderBy('start_level', 'ASC')
            ->get()
            ->map(function ($item) {
                return [
                    'id' => $item->id,
                    'title' => $item->title,
                    'start_level' => intval($item->start_level),
                    'end_level' => intval($item->end_level),
                    'image' => !empty($item->image) ? GlobalFunction::generateFileUrl($item->image) : null,
                ];
            })
            ->values();

        return GlobalFunction::sendDataResponse(true, 'Level badges fetched successfully', $badges);
    }

    public function saveSettings(Request $request)
    {
        $setting = GlobalSettings::first();

        if (!$setting) {
            return response()->json([
                'status' => false,
                'message' => 'Setting Not Found',
            ]);
        }
        if ($request->has('app_name')) {
            $setting->app_name = $request->app_name;
            $request->session()->put('app_name', $setting['app_name']);
        }
        if ($request->has('currency')) {
            $setting->currency = $request->currency;
        }
        if ($request->hasFile('favicon')) {
            $file = $request->file('favicon');
            GlobalFunction::saveFileInLocal($file, 'favicon.png');
        }

        if ($request->hasFile('logo_dark')) {
            $file = $request->file('logo_dark');
            GlobalFunction::saveFileInLocal($file, 'logo-dark.png');
        }
        if ($request->hasFile('logo_light')) {
            $file = $request->file('logo_light');
            GlobalFunction::saveFileInLocal($file, 'logo.png');
        }

        $setting->save();

        return response()->json([
            'status' => true,
            'message' => 'Setting Updated Successfully',
        ]);

    }
    public function saveXpPointsSettings(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'xp_comments_on_live' => 'required|integer|min:0',
            'xp_follow_host' => 'required|integer|min:0',
            'xp_send_gift_per_diamond' => 'required|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => $validator->errors()->first(),
            ]);
        }

        $setting = GlobalSettings::first();

        if (!$setting) {
            return response()->json([
                'status' => false,
                'message' => 'Setting Not Found',
            ]);
        }

        $setting->xp_comments_on_live = intval($request->xp_comments_on_live);
        $setting->xp_follow_host = intval($request->xp_follow_host);
        $setting->xp_send_gift_per_diamond = intval($request->xp_send_gift_per_diamond);
        $setting->save();

        return response()->json([
            'status' => true,
            'message' => 'XP points settings updated successfully',
        ]);
    }
    public function saveAgentSettings(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'agent_commission' => 'required|numeric|min:0',
            'agent_commission_min_withdraw' => 'required|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => $validator->errors()->first(),
            ]);
        }

        $setting = GlobalSettings::first();

        if (!$setting) {
            return response()->json([
                'status' => false,
                'message' => 'Setting Not Found',
            ]);
        }

        $setting->agent_commission = $request->agent_commission;
        $setting->agent_commission_min_withdraw = $request->agent_commission_min_withdraw;
        $setting->save();

        return response()->json([
            'status' => true,
            'message' => 'Agent settings updated successfully',
        ]);
    }

    public function listAgentCommissionSlabs(Request $request)
    {
        $query = AgentCommissionSlab::query();
        $totalData = $query->count();

        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $searchValue = trim((string) $request->input('search.value', ''));

        if ($searchValue !== '') {
            $query->where(function ($q) use ($searchValue) {
                $q->where('start_level', 'LIKE', "%{$searchValue}%")
                    ->orWhere('end_level', 'LIKE', "%{$searchValue}%")
                    ->orWhere('commission_percent', 'LIKE', "%{$searchValue}%");
            });
        }

        $totalFiltered = $query->count();
        $rows = $query->offset($start)
            ->limit($limit)
            ->orderBy('start_level', 'ASC')
            ->orderBy('end_level', 'ASC')
            ->get();

        $data = $rows->map(function ($item) {
            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-startlevel='{$item->start_level}'
                        data-endlevel='{$item->end_level}'
                        data-commissionpercent='{$item->commission_percent}'
                        class='action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-pen'></i>
                        </a>";

            $delete = "<a href='#'
                        rel='{$item->id}'
                        class='action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                        <i class='uil-trash-alt'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";

            return [
                intval($item->start_level),
                intval($item->end_level),
                number_format(floatval($item->commission_percent ?? 0), 2) . '%',
                $action,
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function addAgentCommissionSlab(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'start_level' => 'required|integer|min:1',
            'end_level' => 'required|integer|gte:start_level',
            'commission_percent' => 'required|numeric|min:0|max:99.99',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $startLevel = intval($request->start_level);
        $endLevel = intval($request->end_level);
        $overlap = AgentCommissionSlab::where('start_level', '<=', $endLevel)
            ->where('end_level', '>=', $startLevel)
            ->exists();
        if ($overlap) {
            return GlobalFunction::sendSimpleResponse(false, 'Level range overlaps with existing slab');
        }

        $item = new AgentCommissionSlab();
        $item->start_level = $startLevel;
        $item->end_level = $endLevel;
        $item->commission_percent = round(floatval($request->commission_percent), 2);
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Slab added successfully');
    }

    public function editAgentCommissionSlab(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:agent_commission_slabs,id',
            'start_level' => 'required|integer|min:1',
            'end_level' => 'required|integer|gte:start_level',
            'commission_percent' => 'required|numeric|min:0|max:99.99',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $item = AgentCommissionSlab::find($request->id);
        $startLevel = intval($request->start_level);
        $endLevel = intval($request->end_level);
        $overlap = AgentCommissionSlab::where('id', '!=', $item->id)
            ->where('start_level', '<=', $endLevel)
            ->where('end_level', '>=', $startLevel)
            ->exists();
        if ($overlap) {
            return GlobalFunction::sendSimpleResponse(false, 'Level range overlaps with existing slab');
        }

        $item->start_level = $startLevel;
        $item->end_level = $endLevel;
        $item->commission_percent = round(floatval($request->commission_percent), 2);
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Slab updated successfully');
    }

    public function deleteAgentCommissionSlab(Request $request)
    {
        $item = AgentCommissionSlab::find($request->id);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'Slab not found');
        }
        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'Slab deleted successfully');
    }
    public function saveLimitSettings(Request $request)
    {
        $setting = GlobalSettings::first();

        if (!$setting) {
            return response()->json([
                'status' => false,
                'message' => 'Setting Not Found',
            ]);
        }

        $setting->max_upload_daily = $request->max_upload_daily;
        $setting->max_comment_daily = $request->max_comment_daily;
        $setting->max_comment_reply_daily = $request->max_comment_reply_daily;
        $setting->max_story_daily = $request->max_story_daily;
        $setting->max_comment_pins = $request->max_comment_pins;
        $setting->max_post_pins = $request->max_post_pins;
        $setting->max_user_links = $request->max_user_links;
        $setting->max_images_per_post = $request->max_images_per_post;

        $setting->save();

        return response()->json([
            'status' => true,
            'message' => 'Setting Updated Successfully',
        ]);

    }
    public function saveDeeplinkSettings(Request $request)
    {
        $setting = GlobalSettings::first();

        if (!$setting) {
            return response()->json([
                'status' => false,
                'message' => 'Setting Not Found',
            ]);
        }

        $setting->app_store_download_link = $request->app_store_download_link;
        $setting->play_store_download_link = $request->play_store_download_link;
        $setting->uri_scheme = $request->uri_scheme;

        $setting->save();

        return response()->json([
            'status' => true,
            'message' => 'Setting Updated Successfully',
        ]);

    }
    public function saveLiveStreamSettings(Request $request)
    {
        $setting = GlobalSettings::first();

        if (!$setting) {
            return response()->json([
                'status' => false,
                'message' => 'Setting Not Found',
            ]);
        }

        $setting->live_dummy_show = $request->live_dummy_show;
        $setting->live_battle = $request->live_battle;
        $setting->min_followers_for_live = $request->min_followers_for_live;
        $setting->live_min_viewers = $request->live_min_viewers;
        $setting->live_timeout = $request->live_timeout;
        $setting->battle_duration_minutes = max(1, intval($request->battle_duration_minutes ?? 1));
        $setting->zego_app_sign = $request->zego_app_sign;
        $setting->zego_app_id = $request->zego_app_id;

        $setting->save();

        return response()->json([
            'status' => true,
            'message' => 'Setting Updated Successfully',
        ]);

    }
    public function saveDeepARSettings(Request $request)
    {
        $setting = GlobalSettings::first();

        if (!$setting) {
            return response()->json([
                'status' => false,
                'message' => 'Setting Not Found',
            ]);
        }

        $setting->is_deepAR = $request->is_deepAR;
        $setting->deepar_android_key = $request->deepar_android_key;
        $setting->deepar_iOS_key = $request->deepar_iOS_key;

        $setting->save();

        return response()->json([
            'status' => true,
            'message' => 'Setting Updated Successfully',
        ]);

    }
    public function saveGIFSettings(Request $request)
    {
        $setting = GlobalSettings::first();

        if (!$setting) {
            return response()->json([
                'status' => false,
                'message' => 'Setting Not Found',
            ]);
        }

        $setting->gif_support = $request->gif_support;
        $setting->giphy_key = $request->giphy_key;

        $setting->save();

        return response()->json([
            'status' => true,
            'message' => 'Setting Updated Successfully',
        ]);

    }
    public function saveBasicSettings(Request $request)
    {
        $setting = GlobalSettings::first();

        if (!$setting) {
            return response()->json([
                'status' => false,
                'message' => 'Setting Not Found',
            ]);
        }

        $setting->currency = $request->currency;
        $setting->coin_value = $request->coin_value;
        $setting->diamond_to_star_rate = $request->diamond_to_star_rate;
        $setting->host_commission = $request->host_commission;
        $setting->admin_commision = $request->admin_commision;
        $setting->agent_commision = $request->agent_commision;
        $setting->state_agent_commision = $request->state_agent_commision;
        $setting->gifter_return = $request->gifter_return;
        $setting->min_redeem_coins = $request->min_redeem_coins;

        $setting->is_compress = $request->is_compress;
        $setting->is_withdrawal_on = $request->is_withdrawal_on;
        $setting->registration_bonus_status = $request->registration_bonus_status;
        $setting->registration_bonus_amount = $request->registration_bonus_amount;

        if ($request->has('help_mail')) {
            $setting->help_mail = $request->help_mail;
        }

        $setting->watermark_status = $request->watermark_status;
        if($request->has('watermark_image')){
            if($setting->watermark_image!= null){
                GlobalFunction::deleteFile($setting->watermark_image);
            }
            $setting->watermark_image = GlobalFunction::saveFileAndGivePath($request->watermark_image);
        }

        $setting->save();

        return response()->json([
            'status' => true,
            'message' => 'Setting Updated Successfully',
        ]);

    }
    public function saveContentModerationSettings(Request $request)
    {
        $setting = GlobalSettings::first();

        if (!$setting) {
            return response()->json([
                'status' => false,
                'message' => 'Setting Not Found',
            ]);
        }

        $setting->is_content_moderation = $request->is_content_moderation;
        $setting->sight_engine_api_user = $request->sight_engine_api_user;
        $setting->sight_engine_api_secret = $request->sight_engine_api_secret;
        $setting->sight_engine_video_workflow_id = $request->sight_engine_video_workflow_id;
        $setting->sight_engine_image_workflow_id = $request->sight_engine_image_workflow_id;

        $setting->save();

        return response()->json([
            'status' => true,
            'message' => 'Setting Updated Successfully',
        ]);

    }

    public function changePassword(Request $request)
    {
        $adminUser = Admin::where('user_type', $request->user_type)->first();
        if (!$adminUser) {
            return response()->json([
                'status' => false,
                'message' => 'Admin not found',
            ]);
        }
        if(Session::get('user_type')!= 1){
          return response()->json([
                    'status' => false,
                    'message' => 'Password change not possible!',
                ]);
        }
        if ($request->has('old_password')) {
            if (decrypt($adminUser->admin_password) != $request->old_password) {
                return response()->json([
                    'status' => false,
                    'message' => 'Old Password does not match',
                ]);
            }
            if (decrypt($adminUser->admin_password)  == $request->old_password) {
                $adminUser->admin_password = Crypt::encrypt($request->new_password);
                $adminUser->save();

                $request->session()->put('userpassword', $request->new_password);

                return response()->json([
                    'status' => true,
                    'message' => 'Change Password',
                ]);
            }
        }
    }

    public function admobSettingSave(Request $request)
    {
        $admobSetting = GlobalSettings::first();
        if (!$admobSetting) {
            return response()->json([
                'status' => false,
                'message' => 'Record Not Found',
            ]);
        }

        $admobSetting->admob_banner = $request->admob_banner;
        $admobSetting->admob_int = $request->admob_int;
        $admobSetting->admob_banner_ios = $request->admob_banner_ios;
        $admobSetting->admob_int_ios = $request->admob_int_ios;

        $admobSetting->save();

        return response()->json([
            'status' => true,
            'message' => 'Admob Updated Successfully',
        ]);
    }

    public function updatePrivacyAndTerms(Request $request)
    {
        $setting = GlobalSettings::first();

        if ($request->has('privacy_policy')) {
            $setting->privacy_policy = $request->privacy_policy;
        }

        if ($request->has('terms_of_uses')) {
            $setting->terms_of_uses = $request->terms_of_uses;
        }

        $setting->save();

        return response()->json([
            'status' => true,
            'message' => 'Update successful',
        ]);
    }

    function privacy_policy()
    {
        $setting = GlobalSettings::first();

        return view('privacy_policy', [
            'setting' => $setting,
            'site' => \App\Models\SiteSetting::current(),
            'data' => $setting->privacy_policy
        ]);
    }
    function terms_of_uses()
    {
        $setting = GlobalSettings::first();

        return view('terms_of_uses', [
            'setting' => $setting,
            'site' => \App\Models\SiteSetting::current(),
            'data' => $setting->terms_of_uses
        ]);
    }

    public function imageUploadInEditor(Request $request)
    {
        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $path = $image->store('editor', 'public'); // Save image in 'public/storage/images'
            return response()->json(['imagePath' => $path]);
        }
        return response()->json(['error' => 'No image uploaded'], 400);
    }


    public function uploadFileGivePath(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'file' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $path = GlobalFunction::saveFileAndGivePath($request->file('file'));

        return response()->json([
            'status' => true,
            'message' => "file uploaded, here is the path!",
            'data' => $path,
        ]);
    }
    public function deleteFile(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'filePath' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        GlobalFunction::deleteFile($request->filePath);

        return response()->json([
            'status' => true,
            'message' => "file deleted successfully!",
        ]);
    }



}
