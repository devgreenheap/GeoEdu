<?php

namespace App\Http\Controllers;

use App\Models\Categories;
use App\Models\CountryMaster;
use App\Models\Constants;
use App\Models\FavoriteUsers;
use App\Models\Followers;
use App\Models\AgentCommissionEntries;
use App\Models\GlobalFunction;
use App\Models\GlobalSettings;
use App\Models\Interest;
use App\Models\Language;
use App\Models\LiveStreamComments;
use App\Models\SubCategories;
use App\Models\StateMaster;
use App\Models\Topics;
use App\Models\UserAuthTokens;
use App\Models\UserBlocks;
use App\Models\UserLevels;
use App\Models\UserLinks;
use App\Models\UserNotification;
use App\Models\UserRoleRequests;
use App\Models\ScreenshotDisableRequest;
use App\Models\UsernameRestrictions;
use App\Models\Users;
use App\Mail\OtpMail;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    //
    private function appendSignupNames($user)
    {
        $user->category_name = !empty($user->category_id)
            ? Categories::where('id', intval($user->category_id))->value('name')
            : null;
        $user->sub_category_name = !empty($user->sub_category_id)
            ? SubCategories::where('id', intval($user->sub_category_id))->value('name')
            : null;
        $user->topic_name = !empty($user->topic_id)
            ? Topics::where('id', intval($user->topic_id))->value('name')
            : null;
        $user->language_name = !empty($user->language_id)
            ? Language::where('id', intval($user->language_id))->value('title')
            : null;

        return $user;
    }

    private function findUserByMobileFlexible(string $mobile): ?Users
    {
        $normalized = $this->normalizeMobile($mobile);
        if ($normalized === '' || strlen($normalized) < 6) {
            return null;
        }
        $last10 = strlen($normalized) > 10 ? substr($normalized, -10) : $normalized;

        $candidates = [$normalized, $last10];
        if ($last10 !== '') {
            $candidates[] = '91' . $last10;
            $candidates[] = '+91' . $last10;
            $candidates[] = '0' . $last10;
            $candidates[] = '+' . $last10;
        }
        $candidates = array_values(array_unique(array_filter($candidates, fn($v) => trim((string) $v) !== '')));

        $user = Users::whereIn('user_mobile_no', $candidates)->first();
        if ($user) {
            return $user;
        }

        // Fallback: normalize stored phone formats in SQL and compare last 10 digits.
        return Users::whereRaw(
            "RIGHT(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(user_mobile_no,''), '+',''), '-', ''), ' ', ''), '(', ''), ')', ''), '.', ''), 10) = ?",
            [$last10]
        )->first();
    }

    private function normalizeMobile(string $mobile): string
    {
        $digits = preg_replace('/\D+/', '', trim($mobile)) ?? '';
        if ($digits !== '' && strlen($digits) > 10) {
            $digits = substr($digits, -10);
        }
        return $digits;
    }

    private function sendOtpSms(string $countryCode, string $mobile, string $otp): array
    {
        $senderId = trim((string) (
            env('SMS_SENDER_ID')
            ?: env('OTP_SMS_SENDER')
            ?: 'GREJEW'
        ));
        $apiKey = trim((string) (
            env('SMS_API_KEY')
            ?: env('PAY4SMS_API_KEY')
            ?: env('OTP_SMS_API_KEY')
            ?: ''
        ));
        $credit = intval(
            env('SMS_CREDIT')
            ?: env('OTP_SMS_CREDIT')
            ?: 2
        );
        $templateId = trim((string) (
            env('SMS_TEMPLATE_ID')
            ?: env('OTP_SMS_TEMPLATE_ID')
            ?: ''
        ));
        $message = "Your verification code for Greenheap Gold is: {$otp} This code is valid for 10 minutes. Never share it with anyone, Greenheap Gold and Silver.";
        $encodedMessage = rawurlencode($message);
        $fullMobile = trim($countryCode . $mobile);

        if ($apiKey === '') {
            return [false, 'SMS API key not configured'];
        }

        $url = 'http://pay4sms.in/sendsms/?token=' . $apiKey
            . '&credit=' . $credit
            . '&sender=' . $senderId
            . '&message=' . $encodedMessage
            . '&number=' . $fullMobile;

        if ($templateId !== '') {
            $url .= '&templateid=' . $templateId;
        }

        try {
            $response = Http::timeout(15)->get($url);
            if (!$response->successful()) {
                return [false, 'Failed to send OTP SMS'];
            }
            return [true, 'OTP sent successfully'];
        } catch (\Throwable $e) {
            Log::error('OTP SMS send failed', ['error' => $e->getMessage()]);
            return [false, 'Failed to send OTP SMS'];
        }
    }

    private function sendOtpEmail(string $email, string $otp, int $expireMinutes): array
    {
        try {
            Mail::to($email)->send(new OtpMail($otp, $expireMinutes));
            return [true, 'OTP sent successfully'];
        } catch (\Throwable $e) {
            Log::error('OTP email send failed', ['error' => $e->getMessage()]);
            return [false, 'Failed to send OTP email'];
        }
    }

    public function sendSignupOtp(Request $request)
    {
        if ($request->has('email') && trim((string) $request->email) !== '') {
            return $this->sendSignupOtpByEmail($request);
        }

        if (!$request->has('mobile') && $request->has('user_mobile_no')) {
            $request->merge(['mobile' => $request->input('user_mobile_no')]);
        }

        $validator = Validator::make($request->all(), [
            'mobile' => 'required_without:user_mobile_no|string|max:20',
            'user_mobile_no' => 'required_without:mobile|string|max:20',
            'mobile_country_code' => 'nullable|string|max:10',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $mobile = $this->normalizeMobile((string) $request->mobile);
        if (strlen($mobile) < 6) {
            return GlobalFunction::sendSimpleResponse(false, 'Invalid mobile number');
        }

        $countryCode = trim((string) ($request->mobile_country_code ?? ''));
        if ($countryCode !== '' && strpos($countryCode, '+') !== 0) {
            $countryCode = '+' . ltrim($countryCode, '+');
        }

        if($mobile === '9999988888'){
            $otp ='123456';
        }else{

            $otp = (string) random_int(100000, 999999);
        }

        $expireMinutes = intval(env('OTP_EXPIRE_MINUTES', 10));
        if ($expireMinutes <= 0) {
            $expireMinutes = 10;
        }
        $expiresAt = Carbon::now()->addMinutes($expireMinutes);

        $existing = DB::table('tbl_signup_otps')
            ->where('mobile', $mobile)
            ->where('verified_at', null)
            ->orderBy('id', 'DESC')
            ->first();
        if ($existing && !empty($existing->created_at)) {
            $lastCreated = Carbon::parse($existing->created_at);
            if ($lastCreated->gt(Carbon::now()->subSeconds(30))) {
                return GlobalFunction::sendSimpleResponse(false, 'Please wait before requesting OTP again');
            }
        }

        if($mobile != '9999988888'){
        [$sent, $message] = $this->sendOtpSms($countryCode, $mobile, $otp);
        if (!$sent) {
            return GlobalFunction::sendSimpleResponse(false, $message);
        }
        }

        DB::table('tbl_signup_otps')->insert([
            'mobile_country_code' => $countryCode !== '' ? $countryCode : null,
            'mobile' => $mobile,
            'identity_type' => 'mobile',
            'otp' => $otp,
            'expires_at' => $expiresAt,
            'verified_at' => null,
            'attempts' => 0,
            'created_at' => Carbon::now(),
            'updated_at' => Carbon::now(),
        ]);

        return GlobalFunction::sendDataResponse(true, 'OTP sent successfully', [
            'mobile' => $mobile,
            'expires_in_seconds' => $expireMinutes * 60,
        ]);
    }

    private function sendSignupOtpByEmail(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|max:255',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $email = strtolower(trim((string) $request->email));

        $expireMinutes = intval(env('OTP_EXPIRE_MINUTES', 10));
        if ($expireMinutes <= 0) {
            $expireMinutes = 10;
        }
        $expiresAt = Carbon::now()->addMinutes($expireMinutes);

        $existing = DB::table('tbl_signup_otps')
            ->where('email', $email)
            ->where('verified_at', null)
            ->orderBy('id', 'DESC')
            ->first();
        if ($existing && !empty($existing->created_at)) {
            $lastCreated = Carbon::parse($existing->created_at);
            if ($lastCreated->gt(Carbon::now()->subSeconds(30))) {
                return GlobalFunction::sendSimpleResponse(false, 'Please wait before requesting OTP again');
            }
        }

        // Fixed test identity — mirrors the 9999988888 mobile bypass, for
        // testing when real email delivery can't be verified end-to-end.
        if ($email === 'test@geoedu.com') {
            $otp = '123456';
        } else {
            $otp = (string) random_int(100000, 999999);
            [$sent, $message] = $this->sendOtpEmail($email, $otp, $expireMinutes);
            if (!$sent) {
                return GlobalFunction::sendSimpleResponse(false, $message);
            }
        }

        DB::table('tbl_signup_otps')->insert([
            'email' => $email,
            'identity_type' => 'email',
            'otp' => $otp,
            'expires_at' => $expiresAt,
            'verified_at' => null,
            'attempts' => 0,
            'created_at' => Carbon::now(),
            'updated_at' => Carbon::now(),
        ]);

        return GlobalFunction::sendDataResponse(true, 'OTP sent successfully', [
            'email' => $email,
            'expires_in_seconds' => $expireMinutes * 60,
        ]);
    }

    public function verifySignupOtp(Request $request)
    {
        if (!$request->has('mobile') && $request->has('user_mobile_no')) {
            $request->merge(['mobile' => $request->input('user_mobile_no')]);
        }

        if ($request->has('email') && trim((string) $request->email) !== '') {
            return $this->verifySignupOtpByEmail($request);
        }

        $validator = Validator::make($request->all(), [
            'mobile' => 'required_without:user_mobile_no|string|max:20',
            'user_mobile_no' => 'required_without:mobile|string|max:20',
            'otp' => 'required|string|min:4|max:10',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $mobile = $this->normalizeMobile((string) $request->mobile);
        $otp = trim((string) $request->otp);

        $record = DB::table('tbl_signup_otps')
            ->where('mobile', $mobile)
            ->orderBy('id', 'DESC')
            ->first();

        if (!$record) {
            return GlobalFunction::sendSimpleResponse(false, 'OTP not found');
        }
        if (!is_null($record->verified_at)) {
            return GlobalFunction::sendSimpleResponse(false, 'OTP already verified');
        }
        if (Carbon::parse($record->expires_at)->lt(Carbon::now())) {
            return GlobalFunction::sendSimpleResponse(false, 'OTP expired');
        }
        if ((string) $record->otp !== $otp) {
            DB::table('tbl_signup_otps')
                ->where('id', intval($record->id))
                ->update([
                    'attempts' => intval($record->attempts ?? 0) + 1,
                    'updated_at' => Carbon::now(),
                ]);
            return GlobalFunction::sendSimpleResponse(false, 'Invalid OTP');
        }

        DB::table('tbl_signup_otps')
            ->where('id', intval($record->id))
            ->update([
                'verified_at' => Carbon::now(),
                'updated_at' => Carbon::now(),
            ]);

        return GlobalFunction::sendDataResponse(true, 'OTP verified successfully', [
            'mobile' => $mobile,
            'verified' => true,
        ]);
    }

    private function verifySignupOtpByEmail(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|max:255',
            'otp' => 'required|string|min:4|max:10',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $email = strtolower(trim((string) $request->email));
        $otp = trim((string) $request->otp);

        $record = DB::table('tbl_signup_otps')
            ->where('email', $email)
            ->orderBy('id', 'DESC')
            ->first();

        if (!$record) {
            return GlobalFunction::sendSimpleResponse(false, 'OTP not found');
        }
        if (!is_null($record->verified_at)) {
            return GlobalFunction::sendSimpleResponse(false, 'OTP already verified');
        }
        if (Carbon::parse($record->expires_at)->lt(Carbon::now())) {
            return GlobalFunction::sendSimpleResponse(false, 'OTP expired');
        }
        if ((string) $record->otp !== $otp) {
            DB::table('tbl_signup_otps')
                ->where('id', intval($record->id))
                ->update([
                    'attempts' => intval($record->attempts ?? 0) + 1,
                    'updated_at' => Carbon::now(),
                ]);
            return GlobalFunction::sendSimpleResponse(false, 'Invalid OTP');
        }

        DB::table('tbl_signup_otps')
            ->where('id', intval($record->id))
            ->update([
                'verified_at' => Carbon::now(),
                'updated_at' => Carbon::now(),
            ]);

        return GlobalFunction::sendDataResponse(true, 'OTP verified successfully', [
            'email' => $email,
            'verified' => true,
        ]);
    }

    public function logInWithVerifiedOtp(Request $request)
    {
        if ($request->has('email') && trim((string) $request->email) !== '') {
            return $this->logInWithVerifiedOtpByEmail($request);
        }

        if (!$request->has('mobile') && $request->has('user_mobile_no')) {
            $request->merge(['mobile' => $request->input('user_mobile_no')]);
        }

        $validator = Validator::make($request->all(), [
            'mobile' => 'required_without:user_mobile_no|string|max:20',
            'user_mobile_no' => 'required_without:mobile|string|max:20',
            'device_token' => 'required|string',
            'device' => 'required',
            'login_method' => 'required|string|max:50',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $mobile = $this->normalizeMobile((string) $request->mobile);
        
        
        if ($mobile === '' || strlen($mobile) < 6) {
            return GlobalFunction::sendSimpleResponse(false, 'Invalid mobile number');
        }

        $verifiedOtp = DB::table('tbl_signup_otps')
            ->where('mobile', $mobile)
            ->whereNotNull('verified_at')
            ->orderBy('id', 'DESC')
            ->first();

        if (!$verifiedOtp) {
            return GlobalFunction::sendSimpleResponse(false, 'OTP not verified for this mobile number');
        }

        $mobileCandidates = [$mobile];
        $mobileNoLeadingZero = ltrim($mobile, '0');
        if ($mobileNoLeadingZero !== '' && !in_array($mobileNoLeadingZero, $mobileCandidates, true)) {
            $mobileCandidates[] = $mobileNoLeadingZero;
        }
        if (strlen($mobile) > 10) {
            $last10 = substr($mobile, -10);
            if (!in_array($last10, $mobileCandidates, true)) {
                $mobileCandidates[] = $last10;
            }
        }
        $base10 = strlen($mobile) > 10 ? substr($mobile, -10) : $mobile;
        if ($base10 !== '') {
            $mobileCandidates[] = '+' . $mobile;
            $mobileCandidates[] = '+' . $mobileNoLeadingZero;
            $mobileCandidates[] = '+' . $base10;
            $mobileCandidates[] = '91' . $base10;
            $mobileCandidates[] = '+91' . $base10;
            $mobileCandidates[] = '0' . $base10;
        }
        $mobileCandidates = array_values(array_unique(array_filter($mobileCandidates, fn($v) => trim((string) $v) !== '')));

        $user = Users::whereIn('user_mobile_no', $mobileCandidates)->first();
        if (!$user) {
            $user = $this->findUserByMobileFlexible($mobile);
        }
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found for this mobile number');
        }
        if (intval($user->is_freez ?? 0) === 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $user->device_token = $request->device_token;
        $user->device = $request->device;
        $user->login_method = $request->login_method;
        $user->save();

        $token = GlobalFunction::generateUserAuthToken($user);
        $user = GlobalFunction::prepareUserFullData($user->id);
        $user->new_register = false;
        $user->token = $token;
        $user->following_ids = GlobalFunction::fetchUserFollowingIds($user->id);

        return GlobalFunction::sendDataResponse(true, 'Data Fetch Successful!', $user);
    }

    private function logInWithVerifiedOtpByEmail(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|max:255',
            'device_token' => 'required|string',
            'device' => 'required',
            'login_method' => 'required|string|max:50',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $email = strtolower(trim((string) $request->email));

        $verifiedOtp = DB::table('tbl_signup_otps')
            ->where('email', $email)
            ->whereNotNull('verified_at')
            ->orderBy('id', 'DESC')
            ->first();

        if (!$verifiedOtp) {
            return GlobalFunction::sendSimpleResponse(false, 'OTP not verified for this email');
        }

        $user = Users::whereRaw('LOWER(identity) = ?', [$email])
            ->orWhereRaw('LOWER(user_email) = ?', [$email])
            ->first();
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found for this email');
        }
        if (intval($user->is_freez ?? 0) === 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $user->device_token = $request->device_token;
        $user->device = $request->device;
        $user->login_method = $request->login_method;
        $user->save();

        $token = GlobalFunction::generateUserAuthToken($user);
        $user = GlobalFunction::prepareUserFullData($user->id);
        $user->new_register = false;
        $user->token = $token;
        $user->following_ids = GlobalFunction::fetchUserFollowingIds($user->id);

        return GlobalFunction::sendDataResponse(true, 'Data Fetch Successful!', $user);
    }

    private function applyRegistrationBonusIfEligible(Users $user): void
    {
        if (intval($user->is_dummy ?? 0) === 1 || intval($user->is_verify ?? 0) !== 1) {
            return;
        }
        if (intval($user->registration_bonus_granted ?? 0) === 1) {
            return;
        }

        $settings = GlobalSettings::first();
        if (!$settings || intval($settings->registration_bonus_status ?? 0) !== 1) {
            return;
        }

        $bonus = intval($settings->registration_bonus_amount ?? 0);
        if ($bonus <= 0) {
            return;
        }

        $user->diamond_wallet = intval($user->diamond_wallet ?? 0) + $bonus;
        $user->diamond_collected_lifetime = intval($user->diamond_collected_lifetime ?? 0) + $bonus;
        $user->registration_bonus_granted = 1;
    }

    public function updateUser(Request $request){
        $user = Users::find($request->id);

        if($request->username != $user->username){
            $userExists = Users::where('username', $request->username)->exists();
            if($userExists){
                return GlobalFunction::sendSimpleResponse(false,'Username exists already!');
            }
        }
        if ($request->filled('agent_id')) {
            $agentUser = Users::where('id', $request->agent_id)->where('is_agent', 1)->first();
            if (!$agentUser) {
                return GlobalFunction::sendSimpleResponse(false, 'Selected agent is invalid');
            }
        }
        if($request->has('profile_photo')){
            if($user->profile_photo != null){
                GlobalFunction::deleteFile($user->profile_photo);
            }
            $user->profile_photo = GlobalFunction::saveFileAndGivePath($request->profile_photo);
        }
        $user->username = $request->username;
        $user->fullname = $request->fullname;
        if ($request->has('user_email')) {
            $user->user_email = $request->user_email;
        }
        $user->mobile_country_code = $request->mobile_country_code;
        $user->user_mobile_no = $request->user_mobile_no;
        $user->bio = $request->bio;
        $user->first_name = $request->first_name;
        $user->last_name = $request->last_name;
        $user->gender = $request->gender;
        $user->date_of_birth = $request->date_of_birth;
        $user->country = $request->country;
        $user->state = $request->state;
        $user->city = $request->city;
        $user->zipcode = $request->zipcode;
        $user->address1 = $request->address1;
        $user->address2 = $request->address2;
        $user->college_name = $request->college_name;
        $user->degree = $request->degree;
        $user->full_qualification = $request->full_qualification;
        $user->role = $request->role;
        $user->language_id = $request->language_id;
        $user->level_id = $request->level_id;
        $user->agent_id = $request->filled('agent_id') ? $request->agent_id : null;
        $user->category_id = $request->category_id;
        $user->sub_category_id = $request->sub_category_id;
        $user->topic_id = $request->topic_id;
        $user->is_adult = $request->has('is_adult') ? $request->is_adult : 0;
        if ($request->filled('sub_category_id')) {
            $subCategory = SubCategories::find($request->sub_category_id);
            $user->category_id = $subCategory?->category_id;
        }

        if($user->is_dummy == 1){
            if($request->has('is_verify')){
                $user->is_verify = $request->is_verify;
            }
            if($request->has('password')){
                $user->password = $request->password;
            }
        }
       $user->save();
       return GlobalFunction::sendSimpleResponse(true,'User details updated successfully');
    }
    public function users(){
        $levels = UserLevels::orderBy('level')->get(['id', 'level']);
        return view('users', compact('levels'));
    }

    public function searchUsersForFilter(Request $request)
    {
        $queryText = trim((string) ($request->q ?? ''));
        if ($queryText === '') {
            return GlobalFunction::sendDataResponse(true, 'Users fetched successfully', []);
        }

        $items = Users::select('id', 'username', 'fullname', 'user_mobile_no')
            ->where(function ($q) use ($queryText) {
                $q->where('username', 'LIKE', "%{$queryText}%")
                    ->orWhere('fullname', 'LIKE', "%{$queryText}%");
            })
            ->orderBy('username')
            ->limit(6)
            ->get()
            ->map(function ($item) {
                return [
                    'id' => intval($item->id),
                    'username' => $item->username,
                    'fullname' => $item->fullname,
                    'user_mobile_no' => $item->user_mobile_no,
                ];
            })
            ->values();

        return GlobalFunction::sendDataResponse(true, 'Users fetched successfully', $items);
    }

    public function stateAgentMappings()
    {
        return view('stateAgentMappings');
    }

    public function screenshotDisableRequests()
    {
        return view('screenshotDisableRequests');
    }

    public function listScreenshotDisableRequests(Request $request)
    {
        $query = ScreenshotDisableRequest::query()->with(['user:id,username,fullname', 'approver:id,username,fullname']);
        $totalData = $query->count();

        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $searchValue = trim((string) $request->input('search.value'));
        $statusFilter = $request->input('status');

        if ($statusFilter !== null && $statusFilter !== '') {
            $query->where('status', intval($statusFilter));
        }

        if ($searchValue !== '') {
            $query->where(function ($q) use ($searchValue) {
                $q->where('id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('reason', 'LIKE', "%{$searchValue}%")
                    ->orWhereHas('user', function ($userQuery) use ($searchValue) {
                        $userQuery->where('username', 'LIKE', "%{$searchValue}%")
                            ->orWhere('fullname', 'LIKE', "%{$searchValue}%");
                    });
            });
        }

        $totalFiltered = $query->count();
        $rows = $query->offset($start)->limit($limit)->orderBy('id', 'DESC')->get();

        $data = $rows->map(function ($item) {
            $user = GlobalFunction::createUserDetailsColumn($item->user_id);
            $reason = e($item->reason ?? '-');
            $statusLabel = intval($item->status) === 1
                ? "<span class='badge bg-success'>Approved</span>"
                : "<span class='badge bg-warning text-dark'>Pending</span>";

            $approvedBy = '-';
            if ($item->approver) {
                $approvedByName = trim((string) ($item->approver->fullname ?: $item->approver->username ?: ('User ' . $item->approver->id)));
                $approvedBy = e($approvedByName) . " ({$item->approver->id})";
            }

            $approveBtn = intval($item->status) === 0
                ? "<a href='#' rel='{$item->id}' class='action-btn approve-screenshot-disable d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'><i class='uil-check'></i></a>"
                : '-';

            return [
                "#{$item->id}",
                $user,
                $reason,
                $statusLabel,
                $approvedBy,
                "<span class='d-flex justify-content-end align-items-center'>{$approveBtn}</span>",
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function approveScreenshotDisableRequest(Request $request)
    {
        $requestId = intval($request->id ?? $request->request_id ?? 0);
        if ($requestId <= 0) {
            return GlobalFunction::sendSimpleResponse(false, 'Request id is required');
        }

        $item = ScreenshotDisableRequest::find($requestId);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'Request not found');
        }
        if (intval($item->status) === 1) {
            return GlobalFunction::sendSimpleResponse(false, 'Request already approved');
        }

        $approverId = null;
        try {
            $loggedInAdmin = auth()->user();
            if ($loggedInAdmin && isset($loggedInAdmin->id)) {
                $approverId = intval($loggedInAdmin->id);
            }
        } catch (\Throwable $e) {
            $approverId = null;
        }

        $item->status = 1;
        $item->approved_by = $approverId;
        $item->approved_at = Carbon::now();
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Request approved successfully');
    }

    public function listStateAgentMappings(Request $request)
    {
        $agents = Users::where('is_agent', 1)
            ->where('is_dummy', 0)
            ->orderBy('username')
            ->get(['id', 'username', 'fullname']);

        $query = StateMaster::query()->with(['country:id,name', 'agent:id,username,fullname']);
        $totalData = $query->count();

        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $searchValue = trim((string) $request->input('search.value'));

        if ($searchValue !== '') {
            $query->where(function ($q) use ($searchValue) {
                $q->where('name', 'LIKE', "%{$searchValue}%")
                    ->orWhereHas('country', function ($countryQuery) use ($searchValue) {
                        $countryQuery->where('name', 'LIKE', "%{$searchValue}%");
                    });
            });
        }

        $totalFiltered = $query->count();

        $rows = $query->offset($start)
            ->limit($limit)
            ->orderBy('country_id')
            ->orderBy('name')
            ->get();

        $data = $rows->map(function ($item) use ($agents) {
            $stateName = e($item->name);
            $countryName = e($item->country?->name ?? '-');

            $agentOptions = "<option value=''>" . e(__('Select Agent')) . "</option>";
            foreach ($agents as $agent) {
                $display = trim($agent->username . (!empty($agent->fullname) ? (' - ' . $agent->fullname) : ''));
                $selected = intval($item->agent_id) === intval($agent->id) ? 'selected' : '';
                $agentOptions .= "<option value='{$agent->id}' {$selected}>" . e($display) . "</option>";
            }

            $select = "<select class='form-control form-control-sm state-agent-select' data-state-id='{$item->id}'>{$agentOptions}</select>";
            $saveBtn = "<button type='button' class='btn btn-primary btn-sm save-state-agent' data-state-id='{$item->id}'>Save</button>";

            return [
                $countryName,
                $stateName,
                $select,
                "<span class='d-flex justify-content-end'>{$saveBtn}</span>",
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function saveStateAgentMapping(Request $request)
    {
        $stateId = intval($request->state_id ?? 0);
        $agentId = intval($request->agent_id ?? 0);

        if ($stateId <= 0) {
            return GlobalFunction::sendSimpleResponse(false, 'State is required');
        }
        if ($agentId <= 0) {
            return GlobalFunction::sendSimpleResponse(false, 'Agent is required');
        }

        $state = StateMaster::find($stateId);
        if (!$state) {
            return GlobalFunction::sendSimpleResponse(false, 'State not found');
        }

        $agent = Users::where('id', $agentId)
            ->where('is_agent', 1)
            ->where('is_dummy', 0)
            ->first();
        if (!$agent) {
            return GlobalFunction::sendSimpleResponse(false, 'Selected agent is invalid');
        }

        $state->agent_id = $agent->id;
        $state->save();

        return response()->json([
            'status' => true,
            'message' => 'State agent saved successfully',
            'updated_users' => 0,
        ]);
    }

    public function createDummyUser(){
        $categories = Categories::where('status', 1)->orderBy('name')->get(['id', 'name']);
        $subCategories = SubCategories::where('status', 1)->orderBy('name')->get(['id', 'name', 'category_id']);
        $topics = Topics::where('status', 1)->orderBy('name')->get(['id', 'name', 'sub_category_id']);
        $languages = Language::orderBy('title')->get(['id', 'title', 'code']);
        $levels = UserLevels::orderBy('level')->get(['id', 'level']);
        $agents = Users::where('is_agent', 1)->orderBy('username')->get(['id', 'username', 'fullname']);

        return view('createDummyUser', compact('categories', 'subCategories', 'topics', 'languages', 'levels', 'agents'));
    }
    public function editUser($id){
        $phoneCountryCodes = GlobalFunction::getPhoneCountryCodes();
        $user = Users::find($id);
        $countries = CountryMaster::orderBy('name')->get(['id', 'name']);
        $states = StateMaster::with('country:id,name')->orderBy('name')->get(['id', 'country_id', 'name']);
        $categories = Categories::where('status', 1)->orderBy('name')->get(['id', 'name']);
        $subCategories = SubCategories::where('status', 1)->orderBy('name')->get(['id', 'name', 'category_id']);
        $topics = Topics::where('status', 1)->orderBy('name')->get(['id', 'name', 'sub_category_id']);
        $languages = Language::orderBy('title')->get(['id', 'title', 'code']);
        $levels = UserLevels::orderBy('level')->get(['id', 'level']);
        $agents = Users::where('is_agent', 1)->orderBy('username')->get(['id', 'username', 'fullname']);
        return view('editUser')->with([
            'user'=> $user,
            'phoneCountryCodes'=> $phoneCountryCodes,
            'countries' => $countries,
            'states' => $states,
            'categories' => $categories,
            'subCategories' => $subCategories,
            'topics' => $topics,
            'languages' => $languages,
            'levels' => $levels,
            'agents' => $agents,
        ]);
    }
    public function editDummyUser($id){

        $user = Users::find($id);
        if($user->is_dummy != 1){
            return redirect()->back();
        }
        $phoneCountryCodes = GlobalFunction::getPhoneCountryCodes();
        $countries = CountryMaster::orderBy('name')->get(['id', 'name']);
        $states = StateMaster::with('country:id,name')->orderBy('name')->get(['id', 'country_id', 'name']);
        $categories = Categories::where('status', 1)->orderBy('name')->get(['id', 'name']);
        $subCategories = SubCategories::where('status', 1)->orderBy('name')->get(['id', 'name', 'category_id']);
        $topics = Topics::where('status', 1)->orderBy('name')->get(['id', 'name', 'sub_category_id']);
        $languages = Language::orderBy('title')->get(['id', 'title', 'code']);
        $levels = UserLevels::orderBy('level')->get(['id', 'level']);
        $agents = Users::where('is_agent', 1)->orderBy('username')->get(['id', 'username', 'fullname']);
        return view('editDummyUser')->with([
            'user'=> $user,
            'phoneCountryCodes'=> $phoneCountryCodes,
            'countries' => $countries,
            'states' => $states,
            'categories' => $categories,
            'subCategories' => $subCategories,
            'topics' => $topics,
            'languages' => $languages,
            'levels' => $levels,
            'agents' => $agents,
        ]);
    }
    public function addDummyUser(Request $request){
        $user = Users::where('username', $request->username)->first();
        if($user != null){
            return GlobalFunction::sendSimpleResponse(false,'this username is not available');
        }
            if ($request->filled('agent_id')) {
                $agentUser = Users::where('id', $request->agent_id)->where('is_agent', 1)->first();
                if (!$agentUser) {
                    return GlobalFunction::sendSimpleResponse(false, 'Selected agent is invalid');
                }
            }
            $user = new Users;
            $user->fullname = $request->fullname;
            $user->first_name = $request->first_name;
            $user->last_name = $request->last_name;
            $user->gender = $request->gender;
            $user->date_of_birth = $request->date_of_birth;
            $user->country = $request->country;
            $user->mobile_country_code = $request->mobile_country_code ?? '+91';
            $user->user_mobile_no = $request->user_mobile_no;
            $user->college_name = $request->college_name;
            $user->degree = $request->degree;
            $user->full_qualification = $request->full_qualification;
            $user->role = $request->role;
            $user->bio = $request->bio;
            $user->identity = GlobalFunction::generateDummyUserIdentity();
            $user->username = $request->username;
            $user->password = $request->password;
            $user->is_verify = $request->is_verify;
            $user->is_dummy = Constants::userDummy;
            $user->language_id = $request->language_id;
            $user->level_id = $request->level_id;
            $user->agent_id = $request->filled('agent_id') ? $request->agent_id : null;
            $user->category_id = $request->category_id;
            $user->sub_category_id = $request->sub_category_id;
            $user->topic_id = $request->topic_id;
            $user->is_adult = $request->has('is_adult') ? $request->is_adult : 0;
            if ($request->filled('sub_category_id')) {
                $subCategory = SubCategories::find($request->sub_category_id);
                $user->category_id = $subCategory?->category_id;
            }
            $user->profile_photo = GlobalFunction::saveFileAndGivePath($request->profile_photo);
            $user->save();

            return GlobalFunction::sendSimpleResponse(true,'Dummy user added successfully');
    }

    public function changeUserModeratorStatus(Request $request){
        $user = Users::find($request->user_id);
        $user->is_moderator = $request->is_moderator;
        $user->save();

        return GlobalFunction::sendSimpleResponse(true, 'changes applied successfully');
    }

    public function deleteUserLink_Admin(Request $request){
        $link = UserLinks::find($request->id);
        $link->delete();

        return GlobalFunction::sendSimpleResponse(true,'link deleted successfully');
    }

    public function unFollowUser(Request $request){
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }

        $rules = [
            'user_id' => 'required|exists:tbl_users,id',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }
        $dataUser = GlobalFunction::prepareUserFullData($request->user_id);
        // Self check
        if($user->id == $dataUser->id){
            return GlobalFunction::sendSimpleResponse(false, 'you can not follow/unfollow yourself!');
        }
        $follow = Followers::where([
            'from_user_id'=> $user->id,
            'to_user_id'=> $dataUser->id,
            ])->first();
        if($follow == null){
            return GlobalFunction::sendSimpleResponse(false, 'you are not following this user!');
        }
        $follow->delete();

        GlobalFunction::settleFollowCount($dataUser->id);
        GlobalFunction::settleFollowCount($user->id);

        GlobalFunction::deleteNotifications(Constants::notify_follow_user, $user->id, $user->id);

        return GlobalFunction::sendSimpleResponse(true, 'unfollow successful');

    }
    public function fetchUserFollowings(Request $request){
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }
        $rules = [
            'user_id' => 'required|exists:tbl_users,id',
            'limit' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }
        $dataUser = GlobalFunction::prepareUserFullData($request->user_id);

        //  Check if show my following on/off
        if($dataUser->show_my_following == 0){ //1=yes 0=no
            return GlobalFunction::sendSimpleResponse(false, 'this user has turned off his following show.');
        }

         // Block check
         $isBlock = GlobalFunction::checkUserBlock($user->id, $dataUser->id);
         if($isBlock){
             return GlobalFunction::sendSimpleResponse(false, 'you can not continue this action!');
         }


         $query = Followers::where('from_user_id', $dataUser->id)
                ->orderBy('id', 'DESC')
                ->with(['to_user:'.Constants::userPublicFields])
                ->limit($request->limit);
         if($request->has('last_item_id')){
             $query->where('id','<',$request->last_item_id);
         }
        $data = $query ->get();

        foreach($data as $folliwingItem){
            $folliwingItem->to_user->is_following = false;

            $isFollow =  Followers::where([
                    'from_user_id'=> $user->id,
                    'to_user_id'=> $folliwingItem->to_user_id,
                ])->first();
            if($isFollow != null){
                $folliwingItem->to_user->is_following = true;
            }
        }

        return GlobalFunction::sendDataResponse(true, 'following fetched successfully', $data);


    }
    public function fetchUserFollowers(Request $request){
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }
        $rules = [
            'user_id' => 'required|exists:tbl_users,id',
            'limit' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }
        $dataUser = GlobalFunction::prepareUserFullData($request->user_id);
         // Block check
         $isBlock = GlobalFunction::checkUserBlock($user->id, $dataUser->id);
         if($isBlock){
             return GlobalFunction::sendSimpleResponse(false, 'you can not continue this action!');
         }
         $query = Followers::where('to_user_id', $dataUser->id)
                ->orderBy('id', 'DESC')
                ->with(['from_user:'.Constants::userPublicFields])
                ->limit($request->limit);
         if($request->has('last_item_id')){
             $query->where('id','<',$request->last_item_id);
         }
        $data = $query ->get();

        foreach($data as $followersItem){
            $followersItem->from_user->is_following = false;
            $isFollow =  Followers::where([
                    'from_user_id'=> $user->id,
                    'to_user_id'=> $followersItem->from_user_id,
                ])->first();
            if($isFollow != null){
                $followersItem->from_user->is_following = true;
            }
        }


        return GlobalFunction::sendDataResponse(true, 'followers fetched successfully', $data);


    }
    public function fetchMyFollowings(Request $request){
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }
        $rules = [
            'limit' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

         $query = Followers::where('from_user_id', $user->id)
                ->orderBy('id', 'DESC')
                ->with(['to_user:'.Constants::userPublicFields])
                ->limit($request->limit);
         if($request->has('last_item_id')){
             $query->where('id','<',$request->last_item_id);
         }
        $data = $query ->get();

        return GlobalFunction::sendDataResponse(true, 'my following fetched successfully', $data);

    }

    public function fetchMyFollowers(Request $request){
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }
        $rules = [
            'limit' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

         $query = Followers::where('to_user_id', $user->id)
                ->orderBy('id', 'DESC')
                ->with(['from_user:'.Constants::userPublicFields])
                ->limit($request->limit);
         if($request->has('last_item_id')){
             $query->where('id','<',$request->last_item_id);
         }
        $data = $query ->get();

        foreach($data as $item){
            $item->from_user->is_following = Followers::where([
                'from_user_id'=> $user->id,
                'to_user_id'=> $item->from_user_id,
            ])->exists();
        }

        return GlobalFunction::sendDataResponse(true, 'my followers fetched successfully', $data);

    }
    public function followUser(Request $request){
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }
        $rules = [
            'user_id' => 'required|exists:tbl_users,id',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }
        $dataUser = GlobalFunction::prepareUserFullData($request->user_id);
        // Self check
        if($user->id == $dataUser->id){
            return GlobalFunction::sendSimpleResponse(false, 'you can not follow yourself!');
        }
        $follow = Followers::where([
            'from_user_id'=> $user->id,
            'to_user_id'=> $dataUser->id,
            ])->first();
        if($follow != null){
            return GlobalFunction::sendSimpleResponse(false, 'you are following this user already!');
        }
        // Block check
        $isBlock = GlobalFunction::checkUserBlock($user->id, $dataUser->id);
        if($isBlock){
            return GlobalFunction::sendSimpleResponse(false, 'you can not follow this user!');
        }

        $follow = new Followers();
        $follow->from_user_id = $user->id;
        $follow->to_user_id = $dataUser->id;
        $follow->save();

        GlobalFunction::settleFollowCount($dataUser->id);
        GlobalFunction::settleFollowCount($user->id);
        GlobalFunction::autoUpgradeUserLevel($dataUser->id);

        // Insert Notification Data : Follow User
        $notificationData = GlobalFunction::insertUserNotification(Constants::notify_follow_user,$user->id, $dataUser->id, $user->id);

        return GlobalFunction::sendSimpleResponse(true, 'follow successful');

    }

    public function fetchUserDetails(Request $request){
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }

        $rules = [
            'user_id' => 'required|exists:tbl_users,id',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }
        $baseUser = Users::find($request->user_id);
        $rawLevelId = intval($baseUser->level_id ?? 0);

        GlobalFunction::settleUserTotalPostLikesCount($baseUser->id);
        GlobalFunction::settleFollowCount($baseUser->id);

        $baseUser = Users::find($request->user_id);
        $dataUser = GlobalFunction::prepareUserFullData($baseUser->id);

        // Keep fetchUserDetails in sync with the full tbl_users schema.
        $userTableColumns = Schema::getColumnListing('tbl_users');
        foreach ($userTableColumns as $column) {
            $dataUser->{$column} = $baseUser->getAttribute($column);
        }

        $dataUser->level_id = $rawLevelId;
        $levelValue = UserLevels::where('id', $rawLevelId)->value('level');
        $dataUser->user_level = !is_null($levelValue) && is_numeric($levelValue)
            ? intval($levelValue)
            : null;

        $currentHostFollowers = intval($dataUser->follower_count ?? 0);
        $currentLiveComments = LiveStreamComments::where('sender_id', $dataUser->id)
            ->where('comment_type', Constants::commentTypeText)
            ->count();
        $currentSendGiftDiamonds = intval(
            DB::table('notification_users as n')
                ->join('tbl_gifts as g', 'g.id', '=', 'n.data_id')
                ->where('n.type', Constants::notify_gift_user)
                ->where('n.from_user_id', $dataUser->id)
                ->sum('g.coin_price')
        );

        $orderedLevels = UserLevels::orderByRaw('CAST(level AS UNSIGNED) ASC')
            ->orderBy('level', 'ASC')
            ->get(['id', 'level', 'host_followers_count', 'live_comments_count', 'send_gifts_count']);
        $currentLevelIndex = $orderedLevels->search(function ($level) use ($rawLevelId) {
            return intval($level->id) === intval($rawLevelId);
        });
        $nextLevel = $currentLevelIndex === false
            ? $orderedLevels->first()
            : $orderedLevels->get($currentLevelIndex + 1);
        $nextLevelHostFollowersRequired = intval($nextLevel->host_followers_count ?? 0);
        $nextLevelLiveCommentsRequired = intval($nextLevel->live_comments_count ?? 0);
        $nextLevelSendGiftsRequired = intval($nextLevel->send_gifts_count ?? 0);

        $dataUser->current_host_followers = $currentHostFollowers;
        $dataUser->current_live_comments = intval($currentLiveComments);
        $dataUser->current_send_gifts = intval($currentSendGiftDiamonds);
        $dataUser->current_send_gift_diamonds = intval($currentSendGiftDiamonds);

        $dataUser->next_level_id = !empty($nextLevel->id) ? intval($nextLevel->id) : null;
        $dataUser->next_user_level = !empty($nextLevel->level) && is_numeric($nextLevel->level)
            ? intval($nextLevel->level)
            : null;
        $dataUser->next_level_host_followers_required = $nextLevelHostFollowersRequired;
        $dataUser->next_level_live_comments_required = $nextLevelLiveCommentsRequired;
        $dataUser->next_level_send_gifts_required = $nextLevelSendGiftsRequired;

        $dataUser->next_level_host_followers_remaining = max(0, $nextLevelHostFollowersRequired - $currentHostFollowers);
        $dataUser->next_level_live_comments_remaining = max(0, $nextLevelLiveCommentsRequired - intval($currentLiveComments));
        $dataUser->next_level_send_gifts_remaining = max(0, $nextLevelSendGiftsRequired - intval($currentSendGiftDiamonds));

        $settings = GlobalSettings::first();
        $xpCommentsOnLive = intval($settings->xp_comments_on_live ?? 0);
        $xpFollowHost = intval($settings->xp_follow_host ?? 0);
        $xpSendGiftPerDiamond = intval($settings->xp_send_gift_per_diamond ?? 0);
        $currentXp = (intval($currentLiveComments) * $xpCommentsOnLive)
            + ($currentHostFollowers * $xpFollowHost)
            + (intval($currentSendGiftDiamonds) * $xpSendGiftPerDiamond);
        $nextLevelXpRequired = ($nextLevelLiveCommentsRequired * $xpCommentsOnLive)
            + ($nextLevelHostFollowersRequired * $xpFollowHost)
            + ($nextLevelSendGiftsRequired * $xpSendGiftPerDiamond);

        $dataUser->current_xp = intval($currentXp);
        $dataUser->next_level_xp_required = intval($nextLevelXpRequired);
        $dataUser->next_level_xp_remaining = max(0, intval($nextLevelXpRequired - $currentXp));
         // Check follow
         $dataUser->is_following = Followers::where([
            'from_user_id'=> $user->id,
            'to_user_id'=> $dataUser->id,
        ])->exists();
        $dataUser->is_favorite = FavoriteUsers::where([
            'from_user_id' => $user->id,
            'to_user_id' => $dataUser->id,
        ])->exists();

        // Check follow status
            $following = Followers::where([
                'from_user_id' => $user->id,
                'to_user_id' => $dataUser->id
            ])->exists();

            $follower = Followers::where([
                'from_user_id' => $dataUser->id,
                'to_user_id' => $user->id
            ])->exists();

            if ($following && $follower) {
                $dataUser->follow_status = 3; // Both users follow each other
            } elseif ($following) {
                $dataUser->follow_status = 1; // I am following this user
            } elseif ($follower) {
                $dataUser->follow_status = 2; // The user follows me but I don’t follow back
            } else {
                $dataUser->follow_status = 0; // No follow relationship
            }

        $dataUser->is_block = GlobalFunction::checkUserBlock($user->id, $dataUser->id);
        $dataUser->refer_id = $dataUser->refer_id ?? null;
        $dataUser->totalReferralCount = Users::where('agent_id', intval($user->id))
            ->where('is_dummy', 0)
            ->count();
        $latestScreenshotRequest = ScreenshotDisableRequest::where('user_id', intval($dataUser->id))
            ->orderBy('id', 'DESC')
            ->first(['status']);
        $dataUser->screenshot_disable_status = $latestScreenshotRequest ? intval($latestScreenshotRequest->status) : null;

        // Ensure more-details fields are always present in fetchUserDetails response.
        $dataUser->first_name = $dataUser->first_name ?? null;
        $dataUser->last_name = $dataUser->last_name ?? null;
        $dataUser->gender = $dataUser->gender ?? null;
        $dataUser->date_of_birth = !empty($dataUser->date_of_birth)
            ? Carbon::parse($dataUser->date_of_birth)->format('Y-m-d')
            : null;
        $dataUser->college_name = $dataUser->college_name ?? null;
        $dataUser->degree = $dataUser->degree ?? null;
        $dataUser->full_qualification = $dataUser->full_qualification ?? null;
        $dataUser->role = $dataUser->role ?? null;

        return GlobalFunction::sendDataResponse(true, 'user details fetched successfully', $dataUser);


    }

    public function favoriteUser(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }

        $rules = [
            'user_id' => 'required|exists:tbl_users,id',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $dataUser = GlobalFunction::prepareUserFullData($request->user_id);
        if ($user->id == $dataUser->id) {
            return GlobalFunction::sendSimpleResponse(false, 'you can not favorite yourself!');
        }

        $isBlock = GlobalFunction::checkUserBlock($user->id, $dataUser->id);
        if ($isBlock) {
            return GlobalFunction::sendSimpleResponse(false, 'you can not continue this action!');
        }

        $favorite = FavoriteUsers::where([
            'from_user_id' => $user->id,
            'to_user_id' => $dataUser->id,
        ])->first();
        if ($favorite != null) {
            return GlobalFunction::sendSimpleResponse(false, 'user already in favorites');
        }

        $favorite = new FavoriteUsers();
        $favorite->from_user_id = $user->id;
        $favorite->to_user_id = $dataUser->id;
        $favorite->save();

        return GlobalFunction::sendSimpleResponse(true, 'user added to favorites');
    }

    public function unFavoriteUser(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }

        $rules = [
            'user_id' => 'required|exists:tbl_users,id',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $dataUser = GlobalFunction::prepareUserFullData($request->user_id);
        if ($user->id == $dataUser->id) {
            return GlobalFunction::sendSimpleResponse(false, 'you can not favorite/unfavorite yourself!');
        }

        $favorite = FavoriteUsers::where([
            'from_user_id' => $user->id,
            'to_user_id' => $dataUser->id,
        ])->first();
        if ($favorite == null) {
            return GlobalFunction::sendSimpleResponse(false, 'user is not in favorites');
        }
        $favorite->delete();

        return GlobalFunction::sendSimpleResponse(true, 'user removed from favorites');
    }

    public function fetchMyFavoriteUsers(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }

        $rules = [
            'limit' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $query = FavoriteUsers::where('from_user_id', $user->id)
            ->orderBy('id', 'DESC')
            ->with(['to_user:' . Constants::userPublicFields])
            ->limit($request->limit);
        if ($request->has('last_item_id')) {
            $query->where('id', '<', $request->last_item_id);
        }
        $data = $query->get();

        foreach ($data as $item) {
            if ($item->to_user) {
                $item->to_user->is_following = Followers::where([
                    'from_user_id' => $user->id,
                    'to_user_id' => $item->to_user_id,
                ])->exists();
                $item->to_user->is_favorite = true;
            }
        }

        return GlobalFunction::sendDataResponse(true, 'my favorite users fetched successfully', $data);
    }

    public function fetchMyBlockedUsers(Request $request){
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }
        $items = UserBlocks::where([
            'from_user_id' => $user->id
        ])->with(['to_user:'.Constants::userPublicFields])->get();

        return GlobalFunction::sendDataResponse(true, 'blocked users fetched successfully', $items);

    }

    public function fetchAgentUsers(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }
        if (intval($user->is_agent ?? 0) !== 1) {
            return GlobalFunction::sendSimpleResponse(false, 'Only agent can access this API');
        }

        $validator = Validator::make($request->all(), [
            'limit' => 'nullable|integer|min:1|max:100',
            'last_item_id' => 'nullable|integer|min:1',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $limit = intval($request->limit ?? 20);

        $query = Users::where('agent_id', $user->id)
            ->orderBy('id', 'DESC')
            ->limit($limit);

        if ($request->filled('last_item_id')) {
            $query->where('id', '<', intval($request->last_item_id));
        }

        $users = $query->get();
        $levelNames = UserLevels::pluck('level', 'id');
        $userIds = $users->pluck('id')->map(fn($id) => intval($id))->values()->all();
        $pendingHostRequestUserIds = [];
        if (!empty($userIds)) {
            $pendingHostRequestUserIds = UserRoleRequests::whereIn('user_id', $userIds)
                ->where('request_type', Constants::roleRequestHost)
                ->where('status', Constants::roleRequestPending)
                ->pluck('user_id')
                ->map(fn($id) => intval($id))
                ->unique()
                ->values()
                ->all();
        }
        $pendingHostRequestLookup = array_fill_keys($pendingHostRequestUserIds, true);
        $screenshotRequestLookup = [];
        if (!empty($userIds)) {
            $latestScreenshotRequestRows = ScreenshotDisableRequest::whereIn('user_id', $userIds)
                ->orderBy('id', 'DESC')
                ->get(['id', 'user_id', 'status']);

            foreach ($latestScreenshotRequestRows as $row) {
                $uid = intval($row->user_id);
                if (!isset($screenshotRequestLookup[$uid])) {
                    $screenshotRequestLookup[$uid] = [
                        'request_id' => intval($row->id),
                        'status' => intval($row->status),
                    ];
                }
            }
        }

        $data = $users->map(function ($item) use ($levelNames, $pendingHostRequestLookup, $screenshotRequestLookup) {
            $levelValue = $levelNames[$item->level_id] ?? null;
            $level = is_numeric($levelValue) ? intval($levelValue) : intval($item->level_id ?? 0);
            $screenshotRequest = $screenshotRequestLookup[intval($item->id)] ?? null;

            return [
                'id' => intval($item->id),
                'fullname' => $item->fullname,
                'username' => $item->username,
                'profile_photo' => $item->profile_photo,
                'user_email' => $item->user_email,
                'user_mobile_no' => $item->user_mobile_no,
                'coin_wallet' => intval($item->coin_wallet ?? 0),
                'coin_collected_lifetime' => intval($item->coin_collected_lifetime ?? 0),
                'level' => $level,
                'is_host' => intval($item->is_host ?? 0),
                'host_requested' => isset($pendingHostRequestLookup[intval($item->id)]) ? 1 : 0,
                'is_agent' => intval($item->is_agent ?? 0),
                'follower_count' => intval($item->follower_count ?? 0),
                'following_count' => intval($item->following_count ?? 0),
                'created_at' => !empty($item->created_at) ? Carbon::parse($item->created_at)->format('Y-m-d\TH:i:s') : null,
                'is_freez' => intval($item->is_freez ?? 0),
                'screenshot_disable_requested' => $screenshotRequest ? 1 : 0,
                'screenshot_disable_request_id' => $screenshotRequest['request_id'] ?? null,
                'screenshot_disable_status' => $screenshotRequest['status'] ?? null, // 0=pending, 1=approved
            ];
        })->values();

        return GlobalFunction::sendDataResponse(true, 'Agent users fetched successfully', $data);
    }

    function searchUsers(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }

        $rules = [
            'limit' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }
            $search = GlobalFunction::cleanString($request->keyword);

            $blockedUserIds = GlobalFunction::getUsersBlockedUsersIdsArray($user->id);

            $query =  Users::whereNotIn('id', $blockedUserIds)
                ->where(function ($query) use ($search) {
                    $query->where('fullname', 'LIKE', "%{$search}%")
                        ->orWhere('username', 'LIKE', "%{$search}%");
                })
                ->select(explode(',',Constants::userPublicFields))
                ->where('is_freez', 0)
                ->orderBy('id', 'DESC')
                ->limit($request->limit);
                if($request->has('last_item_id')){
                    $query->where('id','<',$request->last_item_id);
                }
        $data = $query->get();


        foreach($data as $singleUser){
            $singleUser->is_following = false;
            $isFollow =  Followers::where([
                    'from_user_id'=> $user->id,
                    'to_user_id'=> $singleUser->id,
                ])->first();
            if($isFollow != null){
                $singleUser->is_following = true;
            }
        }

        return GlobalFunction::sendDataResponse(true, 'search users fetched successfully', $data);
    }

    public function unBlockUser(Request $request){
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }

        $rules = [
           'user_id' => 'required|exists:tbl_users,id',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }
        $toUser = Users::find($request->user_id);

        if($user->id == $toUser->id){
            return GlobalFunction::sendSimpleResponse(false, 'you can not block/unblock yourself!');
        }
        $item = UserBlocks::where([
            'from_user_id'=> $user->id,
            'to_user_id'=> $toUser->id
        ])->first();
        if($item == null){
            return GlobalFunction::sendSimpleResponse(false, 'this user is not blocked!');
        }
        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'user unblocked successfully');

    }

    public function blockUser(Request $request){

        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }

        $rules = [
            'user_id' => 'required|exists:tbl_users,id',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }
        $toUser = Users::find($request->user_id);

        if($user->id == $toUser->id){
            return GlobalFunction::sendSimpleResponse(false, 'you can not block/unblock yourself!');
        }
        $item = UserBlocks::where([
            'from_user_id'=> $user->id,
            'to_user_id'=> $toUser->id
        ])->first();
        if($item != null){
            return GlobalFunction::sendSimpleResponse(false, 'user is blocked already!');
        }
        $item = new UserBlocks();
        $item->from_user_id = $user->id;
        $item->to_user_id = $toUser->id;
        $item->save();

        // Follow delete if doing
        Followers::where([
            'from_user_id'=> $toUser->id,
            'to_user_id'=> $user->id,
        ])->delete();

        return GlobalFunction::sendSimpleResponse(true, 'user blocked successfully');

    }
    public function viewUserDetails($id){

        $user = GlobalFunction::prepareUserFullData($id);
        $baseUrl = GlobalFunction::getItemBaseUrl();
        $assignedLevel = null;
        if (!empty($user->level_id)) {
            $assignedLevel = UserLevels::where('id', $user->level_id)->value('level');
        }
        $user->levelNumber = $assignedLevel ?? GlobalFunction::determineUserLevel($user->id);

        return view('viewUserDetails',[
            'user'=> $user,
            'baseUrl'=> $baseUrl,
        ]);
    }
    public function listDummyUsers(Request $request)
    {
        $categoryNames = Categories::pluck('name', 'id');
        $subCategoryNames = SubCategories::pluck('name', 'id');
        $topicNames = Topics::pluck('name', 'id');
        $levelNames = UserLevels::pluck('level', 'id');
        $agentNames = Users::pluck('username', 'id');
        $commissionStats = AgentCommissionEntries::selectRaw('agent_id, COUNT(*) as entries_count, SUM(commission_amount) as total_commission')
            ->groupBy('agent_id')
            ->get()
            ->mapWithKeys(function ($item) {
                return [intval($item->agent_id) => [
                    'entries_count' => intval($item->entries_count ?? 0),
                    'total_commission' => floatval($item->total_commission ?? 0),
                ]];
            });
        $languageNames = Language::select('id', 'title', 'code')->get()->mapWithKeys(function ($item) {
            return [$item->id => ($item->title ?? $item->code)];
        });

        $query = Users::query();
        $query->where('is_dummy', 1);
        $totalData = $query->count();

        $columns = ['id'];
        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('fullname', 'LIKE', "%{$searchValue}%")
                ->orWhere('username', 'LIKE', "%{$searchValue}%")
                ->orWhere('identity', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('id', 'DESC')
                        ->get();

        $data = $result->values()->map(function ($item, $index) use ($start, $categoryNames, $subCategoryNames, $topicNames, $languageNames, $levelNames, $agentNames, $commissionStats) {
            $serialNumber = intval($start) + $index + 1;

            $displayUsername = e($item->username ?? '-');
            $displayFullname = e($item->fullname ?? '-');
            $verifyIcon = intval($item->is_verify ?? 0) === 1
                ? "<img src='" . asset('assets/img/ic_verify.png') . "' alt='verified' class='ms-1 rounded-circle object-fit-cover custom-width-18px custom-height-18px'>"
                : '';
            $hostTag = intval($item->is_host ?? 0) === 1
                ? "<span class='badge rounded-pill bg-warning text-dark ms-1'>Host</span>"
                : '';
            $agentTag = intval($item->is_agent ?? 0) === 1
                ? "<span class='badge rounded-pill bg-info ms-1'>Agent</span>"
                : '';
            $userProfileCard = "<a href='" . route('viewUserDetails', $item->id) . "' class='text-decoration-none d-inline-block'><div class='text-dark fw-semibold'>{$displayUsername}{$verifyIcon}{$hostTag}{$agentTag}</div><div class='text-muted fs-6'>{$displayFullname}</div></a>";

            $freeze = GlobalFunction::createUserFreezeSwitch($item,'dummy');

            $moderator = GlobalFunction::createUserModeratorSwitch($item,'dummy');

            $editUserUrl = route('editUser', $item->id);

            $edit = "<a href='$editUserUrl'
                          rel='{$item->id}'
                          class='action-btn d-flex align-items-center justify-content-center btn border rounded-2 text-info ms-1'>
                            <i class='uil-pen'></i>
                        </a>";
            $delete = "<a href='#'
                          rel='{$item->id}'
                          class='action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                            <i class='uil-trash-alt'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";


            $identity = "<h5>{$item->identity}</h5>";
            $password = "<p class='m-0'>{$item->password}</p>";
            $identity_password = '<div class="">'.$identity.$password.'</div>';
            $mobile = e((string) ($item->user_mobile_no ?? '-'));
            $commissionDetails = $commissionStats[intval($item->id)] ?? ['entries_count' => 0, 'total_commission' => 0];
            $commissionHtml = '';
            if (intval($item->is_agent ?? 0) === 1) {
                $commissionHtml = "
                <p class='m-0'><strong>Commission Wallet:</strong> ".GlobalFunction::formatNumber($item->agent_commission_wallet ?? 0)."</p>";
            }
            $learningData = "<div>
                <p class='m-0'><strong>Level:</strong> ".($levelNames[$item->level_id] ?? '-')."</p>
                <p class='m-0'><strong>Star:</strong> ".GlobalFunction::formatNumber($item->coin_wallet)."</p>
                <p class='m-0'><strong>Diamond:</strong> ".GlobalFunction::formatNumber($item->diamond_wallet ?? 0)."</p>
                {$commissionHtml}
            </div>";

            return [
                $serialNumber,
                $userProfileCard,
                $identity_password,
                $mobile,
                $learningData,
                $freeze,
                $moderator,
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
    public function listAllModerators(Request $request)
    {
        $categoryNames = Categories::pluck('name', 'id');
        $subCategoryNames = SubCategories::pluck('name', 'id');
        $topicNames = Topics::pluck('name', 'id');
        $levelNames = UserLevels::pluck('level', 'id');
        $agentNames = Users::pluck('username', 'id');
        $commissionStats = AgentCommissionEntries::selectRaw('agent_id, COUNT(*) as entries_count, SUM(commission_amount) as total_commission')
            ->groupBy('agent_id')
            ->get()
            ->mapWithKeys(function ($item) {
                return [intval($item->agent_id) => [
                    'entries_count' => intval($item->entries_count ?? 0),
                    'total_commission' => floatval($item->total_commission ?? 0),
                ]];
            });
        $languageNames = Language::select('id', 'title', 'code')->get()->mapWithKeys(function ($item) {
            return [$item->id => ($item->title ?? $item->code)];
        });

        $query = Users::query();
        $query->where('is_moderator', 1);
        $totalData = $query->count();

        $columns = ['id'];
        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('fullname', 'LIKE', "%{$searchValue}%")
                ->orWhere('username', 'LIKE', "%{$searchValue}%")
                ->orWhere('identity', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('id', 'DESC')
                        ->get();

        $data = $result->values()->map(function ($item, $index) use ($start, $categoryNames, $subCategoryNames, $topicNames, $languageNames, $levelNames, $agentNames, $commissionStats) {
            $serialNumber = intval($start) + $index + 1;

            $displayUsername = e($item->username ?? '-');
            $displayFullname = e($item->fullname ?? '-');
            $verifyIcon = intval($item->is_verify ?? 0) === 1
                ? "<img src='" . asset('assets/img/ic_verify.png') . "' alt='verified' class='ms-1 rounded-circle object-fit-cover custom-width-18px custom-height-18px'>"
                : '';
            $hostTag = intval($item->is_host ?? 0) === 1
                ? "<span class='badge rounded-pill bg-warning text-dark ms-1'>Host</span>"
                : '';
            $agentTag = intval($item->is_agent ?? 0) === 1
                ? "<span class='badge rounded-pill bg-info ms-1'>Agent</span>"
                : '';
            $userProfileCard = "<a href='" . route('viewUserDetails', $item->id) . "' class='text-decoration-none d-inline-block'><div class='text-dark fw-semibold'>{$displayUsername}{$verifyIcon}{$hostTag}{$agentTag}</div><div class='text-muted fs-6'>{$displayFullname}</div></a>";

            $realOrFake = GlobalFunction::createUserTypeBadge($item->id);

            $freeze = GlobalFunction::createUserFreezeSwitch($item,'moderators');

            $moderator = GlobalFunction::createUserModeratorSwitch($item,'moderators');

            $editUserUrl = route('editUser', $item->id);

            $edit = "<a href='$editUserUrl'
                          rel='{$item->id}'
                          class='action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-info ms-1'>
                            <i class='uil-pen'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}</span>";
            $commissionDetails = $commissionStats[intval($item->id)] ?? ['entries_count' => 0, 'total_commission' => 0];
            $mobile = e((string) ($item->user_mobile_no ?? '-'));
            $commissionHtml = '';
            if (intval($item->is_agent ?? 0) === 1) {
                $commissionHtml = "
                <p class='m-0'><strong>Commission Wallet:</strong> ".GlobalFunction::formatNumber($item->agent_commission_wallet ?? 0)."</p>";
            }
            $learningData = "<div>
                <p class='m-0'><strong>Level:</strong> ".($levelNames[$item->level_id] ?? '-')."</p>
                <p class='m-0'><strong>Star:</strong> ".GlobalFunction::formatNumber($item->coin_wallet)."</p>
                <p class='m-0'><strong>Diamond:</strong> ".GlobalFunction::formatNumber($item->diamond_wallet ?? 0)."</p>
                {$commissionHtml}
            </div>";

            return [
                $serialNumber,
                $userProfileCard,
                $realOrFake,
                $item->identity,
                $mobile,
                $learningData,
                $freeze,
                $moderator,
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
    public function listAllUsers(Request $request)
    {
        $categoryNames = Categories::pluck('name', 'id');
        $subCategoryNames = SubCategories::pluck('name', 'id');
        $topicNames = Topics::pluck('name', 'id');
        $levelNames = UserLevels::pluck('level', 'id');
        $agentNames = Users::pluck('username', 'id');
        $commissionStats = AgentCommissionEntries::selectRaw('agent_id, COUNT(*) as entries_count, SUM(commission_amount) as total_commission')
            ->groupBy('agent_id')
            ->get()
            ->mapWithKeys(function ($item) {
                return [intval($item->agent_id) => [
                    'entries_count' => intval($item->entries_count ?? 0),
                    'total_commission' => floatval($item->total_commission ?? 0),
                ]];
            });
        $languageNames = Language::select('id', 'title', 'code')->get()->mapWithKeys(function ($item) {
            return [$item->id => ($item->title ?? $item->code)];
        });

        $query = Users::query();
        $totalData = $query->count();

        $columns = ['id'];
        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        $levelId = intval($request->input('level_id') ?? 0);
        $userType = strtolower(trim((string) ($request->input('user_type') ?? 'all')));
        $roleType = strtolower(trim((string) ($request->input('role_type') ?? 'all')));
        $filterName = trim((string) ($request->input('filter_name') ?? ''));
        $filterMobile = trim((string) ($request->input('mobile') ?? ''));

        if ($levelId > 0) {
            $query->where('level_id', $levelId);
        }

        if ($userType === 'real') {
            $query->where('is_dummy', 0);
        } elseif ($userType === 'dummy') {
            $query->where('is_dummy', 1);
        }

        if ($roleType === 'user') {
            $query->where('is_host', 0)->where('is_agent', 0);
        } elseif ($roleType === 'host') {
            $query->where('is_host', 1);
        } elseif ($roleType === 'agent') {
            $query->where('is_agent', 1);
        } elseif ($roleType === 'state_agent') {
            $stateAgentIds = StateMaster::whereNotNull('agent_id')
                ->where('agent_id', '>', 0)
                ->distinct()
                ->pluck('agent_id')
                ->map(fn($id) => intval($id))
                ->filter(fn($id) => $id > 0)
                ->values()
                ->toArray();

            if (empty($stateAgentIds)) {
                $query->whereRaw('1 = 0');
            } else {
                $query->whereIn('id', $stateAgentIds);
            }
        }

        if ($filterName !== '') {
            $query->where(function ($q) use ($filterName) {
                $q->where('fullname', 'LIKE', "%{$filterName}%")
                    ->orWhere('username', 'LIKE', "%{$filterName}%");
            });
        }

        if ($filterMobile !== '') {
            $query->where('user_mobile_no', 'LIKE', "%{$filterMobile}%");
        }

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('fullname', 'LIKE', "%{$searchValue}%")
                ->orWhere('username', 'LIKE', "%{$searchValue}%")
                ->orWhere('identity', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('id', 'DESC')
                        ->get();

        $data = $result->values()->map(function ($item, $index) use ($start, $categoryNames, $subCategoryNames, $topicNames, $languageNames, $levelNames, $agentNames, $commissionStats) {
            $serialNumber = intval($start) + $index + 1;

            $displayUsername = e($item->username ?? '-');
            $displayFullname = e($item->fullname ?? '-');
            $verifyIcon = intval($item->is_verify ?? 0) === 1
                ? "<img src='" . asset('assets/img/ic_verify.png') . "' alt='verified' class='ms-1 rounded-circle object-fit-cover custom-width-18px custom-height-18px'>"
                : '';
            $hostTag = intval($item->is_host ?? 0) === 1
                ? "<span class='badge rounded-pill bg-warning text-dark ms-1'>Host</span>"
                : '';
            $agentTag = intval($item->is_agent ?? 0) === 1
                ? "<span class='badge rounded-pill bg-info ms-1'>Agent</span>"
                : '';
            $userProfileCard = "<a href='" . route('viewUserDetails', $item->id) . "' class='text-decoration-none d-inline-block'><div class='text-dark fw-semibold'>{$displayUsername}{$verifyIcon}{$hostTag}{$agentTag}</div><div class='text-muted fs-6'>{$displayFullname}</div></a>";

            $realOrFake = GlobalFunction::createUserTypeBadge($item->id);

            $freeze = GlobalFunction::createUserFreezeSwitch($item, 'all');

            $moderator = GlobalFunction::createUserModeratorSwitch($item,'all');

            $editUserUrl = route('editUser', $item->id);

            $edit = "<a href='$editUserUrl'
                          rel='{$item->id}'
                          class='action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-info ms-1'>
                            <i class='uil-pen'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}</span>";
            $commissionDetails = $commissionStats[intval($item->id)] ?? ['entries_count' => 0, 'total_commission' => 0];
            $mobile = e((string) ($item->user_mobile_no ?? '-'));
            $commissionHtml = '';
            if (intval($item->is_agent ?? 0) === 1) {
                $commissionHtml = "
                <p class='m-0'><strong>Commission Wallet:</strong> ".GlobalFunction::formatNumber($item->agent_commission_wallet ?? 0)."</p>";
            }
            $learningData = "<div>
                <p class='m-0'><strong>Level:</strong> ".($levelNames[$item->level_id] ?? '-')."</p>
                <p class='m-0'><strong>Star:</strong> ".GlobalFunction::formatNumber($item->coin_wallet)."</p>
                <p class='m-0'><strong>Diamond:</strong> ".GlobalFunction::formatNumber($item->diamond_wallet ?? 0)."</p>
                {$commissionHtml}
            </div>";

            return [
                $serialNumber,
                $userProfileCard,
                $realOrFake,
                $item->identity,
                $mobile,
                $learningData,
                $freeze,
                $moderator,
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
    public function userFreezeUnfreeze(Request $request){
        $user = Users::find($request->user_id);
        $user->is_freez = $request->is_freez;
        $user->save();

        return GlobalFunction::sendSimpleResponse(true, 'Task successful');
    }
    public function updateLastUsedAt(Request $request){

        // Validate user token and fetch user
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        $user->app_last_used_at = Carbon::now();
        $user->save();

        return GlobalFunction::sendSimpleResponse(true, 'last log in updated successfully');

    }

    public function checkUsernameAvailability(Request $request){
        $validator = Validator::make($request->all(), [
            'username' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $user = Users::where('username', $request->username)->first();
        if($user){
            return GlobalFunction::sendSimpleResponse(false, 'username not available!');
        }

        return GlobalFunction::sendSimpleResponse(true, 'username available!');

    }

    public function editeUserLink(Request $request){

        $validator = Validator::make($request->all(), [
            'link_id' => 'required|exists:user_links,id',
            'title' => 'required',
            'url' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        // Validate user token and fetch user
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return response()->json(['status' => false, 'message' => "this user is freezed!"]);
        }
        $link = UserLinks::find($request->link_id);
        if(!$link){
            return GlobalFunction::sendSimpleResponse(false, 'Link not found!');
        }
        if($link->user_id != $user->id){
            return GlobalFunction::sendSimpleResponse(false, 'this link is not owned by this user!');
        }
        $link->title = $request->title;
        $link->url = $request->url;
        $link->save();

        return GlobalFunction::sendDataResponse(true, 'user link edited successfully!', $user->links);

    }
    public function deleteUserLink(Request $request){

        $validator = Validator::make($request->all(), [
            'link_id' => 'required|exists:user_links,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        // Validate user token and fetch user
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return response()->json(['status' => false, 'message' => "this user is freezed!"]);
        }
        $link = UserLinks::find($request->link_id);
        if(!$link){
            return GlobalFunction::sendSimpleResponse(false, 'Link not found!');
        }
        if($link->user_id != $user->id){
            return GlobalFunction::sendSimpleResponse(false, 'this link is not owned by this user!');
        }
        $link->delete();

        return GlobalFunction::sendDataResponse(true, 'user link deleted successfully!', $user->links);

    }
    public function deleteMyAccount(Request $request){
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user) {
           GlobalFunction::deleteUserAccount($user);
        }
        $user->delete();
         return GlobalFunction::sendSimpleResponse(true, 'account deleted successfully');
    }
    public function deleteDummyUser(Request $request){
        $user = Users::find($request->id);
        if ($user) {
           GlobalFunction::deleteUserAccount($user);
        }
        $user->delete();
         return GlobalFunction::sendSimpleResponse(true, 'User deleted successfully');
    }


    public function addUserLink(Request $request){

        $validator = Validator::make($request->all(), [
            'url' => 'required',
            'title' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        // Validate user token and fetch user
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return response()->json(['status' => false, 'message' => "this user is freezed!"]);
        }

        $link = new UserLinks();
        $link->user_id = $user->id;
        $link->title = $request->title;
        $link->url = $request->url;
        $link->save();

        return GlobalFunction::sendDataResponse(true, 'user link added successfully!', $user->links);

    }

    public function fetchMyInterests(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }

        return GlobalFunction::sendDataResponse(true, 'my interests', $user->interests);
    }

    public function updateMyInterests(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return response()->json(['status' => false, 'message' => "this user is freezed!"]);
        }

        $interestIds = array_filter(array_map('intval', explode(',', (string) $request->interest_ids)));
        $validIds = Interest::whereIn('id', $interestIds)->where('status', 1)->pluck('id')->toArray();

        $user->interests()->sync($validIds);

        return GlobalFunction::sendDataResponse(true, 'interests updated successfully', $user->interests()->get());
    }

    public function updateUserDetails(Request $request)
    {
        $token = $request->header('authtoken');

        if (!$request->has('mobile') && $request->has('user_mobile_no')) {
            $request->merge(['mobile' => $request->input('user_mobile_no')]);
        }
        if (!$request->has('user_email') && $request->has('email')) {
            $request->merge(['user_email' => $request->input('email')]);
        }

        // Validate user token and fetch user
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return response()->json(['status' => false, 'message' => "this user is freezed!"]);
        }

        $validator = Validator::make($request->all(), [
            'fullname' => 'nullable|string|max:255',
            'first_name' => 'nullable|string|max:100',
            'last_name' => 'nullable|string|max:100',
            'username' => 'nullable|string|max:255',
            'gender' => 'nullable|string|max:30',
            'date_of_birth' => 'nullable|date_format:Y-m-d',
            'user_email' => 'nullable|email|max:255',
            'email' => 'nullable|email|max:255',
            'country' => 'nullable|string|max:120',
            'state' => 'nullable|string|max:120',
            'city' => 'nullable|string|max:120',
            'zipcode' => 'nullable|string|max:30',
            'address1' => 'nullable|string|max:255',
            'address2' => 'nullable|string|max:255',
            'mobile' => 'nullable|string|max:30',
            'user_mobile_no' => 'nullable|string|max:30',
            'mobile_country_code' => 'nullable|string|max:10',
            'college_name' => 'nullable|string|max:255',
            'degree' => 'nullable|string|max:255',
            'highest_degree' => 'nullable|string|max:255',
            'full_qualification' => 'nullable|string|max:255',
            'role' => 'nullable|in:Student,Professor',
            'bio' => 'nullable|string|max:1000',
            'instagram_handle' => 'nullable|string|max:100',
            'app_language' => 'nullable|string|max:20',
            'profile_photo' => 'nullable',
            'bank_name' => 'nullable|string|max:255',
            'account_number' => 'nullable|string|max:100',
            'ifsc_code' => 'nullable|string|max:50',
            'branch_name' => 'nullable|string|max:255',
            'category_id' => 'nullable|exists:tbl_categories,id',
            'sub_category_id' => 'nullable|exists:tbl_sub_categories,id',
            'topic_id' => 'nullable|exists:tbl_topics,id',
            'language_id' => 'nullable|exists:languages,id',
            'level_id' => 'nullable|exists:user_levels,id',
            'is_adult' => 'nullable|boolean',
            'notify_post_like' => 'nullable|boolean',
            'notify_post_comment' => 'nullable|boolean',
            'notify_follow' => 'nullable|boolean',
            'notify_mention' => 'nullable|boolean',
            'notify_gift_received' => 'nullable|boolean',
            'notify_chat' => 'nullable|boolean',
            'receive_message' => 'nullable|boolean',
            'show_my_following' => 'nullable|boolean',
            'who_can_view_post' => 'nullable',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $oldIsVerify = intval($user->is_verify ?? 0);

        // Define fields to update
        $updatableFields = [
            'fullname',
            'first_name',
            'last_name',
            'gender',
            'date_of_birth',
            'user_email',
            'user_mobile_no',
            'mobile_country_code',
            'device_token',
            'bio',
            'instagram_handle',
            'country',
            'state',
            'zipcode',
            'address1',
            'address2',
            'countryCode',
            'college_name',
            'degree',
            'highest_degree',
            'full_qualification',
            'role',
            'bank_name',
            'account_number',
            'ifsc_code',
            'branch_name',
            'region',
            'regionName',
            'city',
            'lon',
            'lat',
            'timezone',
            'notify_post_like',
            'notify_post_comment',
            'notify_follow',
            'notify_mention',
            'notify_gift_received',
            'notify_chat',
            'receive_message',
            'show_my_following',
            'who_can_view_post',
            'saved_music_ids',
            'app_language',
            'is_verify',
            'category_id',
            'sub_category_id',
            'topic_id',
            'language_id',
            'level_id',
            'is_adult',
        ];

        // Update user fields dynamically
        foreach ($updatableFields as $field) {
            if ($request->has($field)) {
                $user->$field = $request->$field;
            }
        }
        if ($request->has('mobile')) {
            $user->user_mobile_no = $request->mobile;
        }
        if ($request->has('sub_category_id')) {
            $subCategory = SubCategories::find($request->sub_category_id);
            if ($subCategory) {
                $user->category_id = $subCategory->category_id;
            }
        }

        // Handle profile photo separately
        if ($request->has('profile_photo')) {
            if ($user->profile_photo) {
                GlobalFunction::deleteFile($user->profile_photo);
            }
            $user->profile_photo = GlobalFunction::saveFileAndGivePath($request->profile_photo);
        }
        // Handle Username
        if ($request->has('username')) {
            $user2 = Users::where('username', $request->username)->first();
            if($user2 && $user2->id != $user->id){
                return GlobalFunction::sendSimpleResponse(false, 'username is not available!');
            }
            $restriction = UsernameRestrictions::where('username', $request->username)->first();
            if($restriction){
                return GlobalFunction::sendSimpleResponse(false, 'username is not available!');
            }
            $user->username = $request->username;
        }

        // Apply registration bonus only after verification happens.
        if ($oldIsVerify === 0 && intval($user->is_verify ?? 0) === 1) {
            $this->applyRegistrationBonusIfEligible($user);
        }

        // Save updated user details
        $user->save();
        $user = GlobalFunction::prepareUserFullData($user->id);

        $userTableColumns = Schema::getColumnListing('tbl_users');
        foreach ($userTableColumns as $column) {
            $user->{$column} = $user->getAttribute($column);
        }

        return GlobalFunction::sendDataResponse(true, 'User details updated successfully', $user);
    }

    public function updateUserMoreDetails(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return response()->json(['status' => false, 'message' => 'this user is freezed!']);
        }

        $validator = Validator::make($request->all(), [
            'first_name' => 'nullable|string|max:100',
            'last_name' => 'nullable|string|max:100',
            'gender' => 'nullable|string|max:30',
            'date_of_birth' => 'nullable|date',
            'country' => 'nullable|string|max:100',
            'college_name' => 'nullable|string|max:255',
            'degree' => 'nullable|string|max:255',
            'full_qualification' => 'nullable|string|max:255',
            'role' => 'nullable|string|max:100',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $fields = [
            'first_name',
            'last_name',
            'gender',
            'date_of_birth',
            'country',
            'college_name',
            'degree',
            'full_qualification',
            'role',
        ];

        foreach ($fields as $field) {
            if ($request->has($field)) {
                $value = $request->$field;
                if (is_string($value)) {
                    $value = trim($value);
                }
                $user->$field = $value === '' ? null : $value;
            }
        }

        $user->save();

        return GlobalFunction::sendDataResponse(true, 'More details updated successfully', [
            'first_name' => $user->first_name,
            'last_name' => $user->last_name,
            'gender' => $user->gender,
            'date_of_birth' => $user->date_of_birth,
            'country' => $user->country,
            'college_name' => $user->college_name,
            'degree' => $user->degree,
            'full_qualification' => $user->full_qualification,
            'role' => $user->role,
        ]);
    }

    public function fetchUserMoreDetails(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return response()->json(['status' => false, 'message' => 'this user is freezed!']);
        }

        return GlobalFunction::sendDataResponse(true, 'More details fetched successfully', [
            'first_name' => $user->first_name,
            'last_name' => $user->last_name,
            'gender' => $user->gender,
            'date_of_birth' => $user->date_of_birth,
            'country' => $user->country,
            'college_name' => $user->college_name,
            'degree' => $user->degree,
            'full_qualification' => $user->full_qualification,
            'role' => $user->role,
        ]);
    }


    function logInUser(Request $request){
        if (!$request->has('mobile') && $request->has('user_mobile_no')) {
            $request->merge(['mobile' => $request->input('user_mobile_no')]);
        }
        if (!$request->has('address1') && $request->has('address_1')) {
            $request->merge(['address1' => $request->input('address_1')]);
        }
        if (!$request->has('address2') && $request->has('address_2')) {
            $request->merge(['address2' => $request->input('address_2')]);
        }

        $validator = Validator::make($request->all(), [
            'fullname' => 'nullable|string|max:255',
            'identity' => 'required',
            'device_token' => 'required',
            'device' => 'required',
            'login_method' => 'required',
            'address1' => 'nullable|string|max:255',
            'address2' => 'nullable|string|max:255',
            'address_1' => 'nullable|string|max:255',
            'address_2' => 'nullable|string|max:255',
            'city' => 'nullable|string|max:120',
            'state' => 'nullable|string|max:120',
            'country' => 'nullable|string|max:120',
            'zipcode' => 'nullable|string|max:30',
            'mobile' => 'nullable|string|max:30',
            'user_mobile_no' => 'nullable|string|max:30',
            'refer_id' => 'nullable|string|max:255',
            'category_id' => 'nullable|exists:tbl_categories,id',
            'sub_category_id' => 'nullable|exists:tbl_sub_categories,id',
            'topic_id' => 'nullable|exists:tbl_topics,id',
            'language_id' => 'nullable|exists:languages,id',
            'level_id' => 'nullable|exists:user_levels,id',
            'is_adult' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $normalizedSignupMobile = null;
        if ($request->has('mobile')) {
            $normalizedSignupMobile = $this->normalizeMobile((string) $request->mobile);
            if ($normalizedSignupMobile === '' || strlen($normalizedSignupMobile) < 6) {
                return GlobalFunction::sendSimpleResponse(false, 'Invalid mobile number');
            }
        }

        $identityValue = trim((string) $request->identity);
        $user = Users::where('identity', $identityValue)->first();
        if (!$user) {
            $identityMobile = $this->normalizeMobile($identityValue);
            $mobileCandidates = [];

            if ($identityValue !== '') {
                $mobileCandidates[] = $identityValue;
            }
            if ($identityMobile !== '') {
                $mobileCandidates[] = $identityMobile;
                $mobileCandidates[] = '+' . $identityMobile;

                $mobileNoLeadingZero = ltrim($identityMobile, '0');
                if ($mobileNoLeadingZero !== '' && !in_array($mobileNoLeadingZero, $mobileCandidates, true)) {
                    $mobileCandidates[] = $mobileNoLeadingZero;
                    $mobileCandidates[] = '+' . $mobileNoLeadingZero;
                }
                if (strlen($identityMobile) > 10) {
                    $last10 = substr($identityMobile, -10);
                    if (!in_array($last10, $mobileCandidates, true)) {
                        $mobileCandidates[] = $last10;
                        $mobileCandidates[] = '+' . $last10;
                    }
                }
            }
            $mobileCandidates = array_values(array_unique(array_filter($mobileCandidates, fn($v) => trim((string) $v) !== '')));

            if (!empty($mobileCandidates)) {
                $user = Users::whereIn('user_mobile_no', $mobileCandidates)->first();
            }
            if (!$user && $identityMobile !== '') {
                $user = $this->findUserByMobileFlexible($identityMobile);
            }
            if ($user && empty($user->identity)) {
                $user->identity = $identityValue;
            }
        }

        if ($user == null) {
            $fullName = trim((string) ($request->fullname ?? ''));
            if ($fullName === '') {
                return GlobalFunction::sendSimpleResponse(false, 'The fullname field is required.');
            }

            if (!is_null($normalizedSignupMobile)) {
                $mobileExists = Users::where('user_mobile_no', $normalizedSignupMobile)->exists();
                if ($mobileExists) {
                    return GlobalFunction::sendSimpleResponse(false, 'Mobile number already exists');
                }
            }

            $user = new Users;
            $user->fullname = GlobalFunction::cleanString($fullName);
            $user->identity = $request->identity;
            $user->device_token = $request->device_token;
            $user->device = $request->device;
            $user->login_method = $request->login_method;
            $user->username = GlobalFunction::generateUsername($user->fullname);
            $user->category_id = $request->category_id;
            $user->sub_category_id = $request->sub_category_id;
            $user->topic_id = $request->topic_id;
            $user->language_id = $request->language_id;
            $user->level_id = $request->level_id;
            $user->is_adult = $request->has('is_adult') ? $request->is_adult : 0;
            $user->address1 = $request->address1;
            $user->address2 = $request->address2;
            $user->city = $request->city;
            $user->state = $request->state;
            $user->country = $request->country;
            $user->zipcode = $request->zipcode;
            if (!is_null($normalizedSignupMobile)) {
                $user->user_mobile_no = $normalizedSignupMobile;
            }

            if ($request->filled('refer_id')) {
                $referCode = trim((string) $request->refer_id);
                if (!preg_match('/(\d+)$/', $referCode, $matches)) {
                    return GlobalFunction::sendSimpleResponse(false, 'Invalid refer_id format');
                }

                $referredAgentId = intval($matches[1]);
                $agentUser = Users::where('id', $referredAgentId)->where('is_agent', 1)->first();
                if (!$agentUser) {
                    return GlobalFunction::sendSimpleResponse(false, 'Invalid refer_id. Agent not found');
                }

                $user->refer_id = $referCode;
                $user->agent_id = $agentUser->id;
            }

            if ($request->filled('sub_category_id')) {
                $subCategory = SubCategories::find($request->sub_category_id);
                $user->category_id = $subCategory?->category_id;
            }

            if ($request->has('profile_photo')) {
                $user->profile_photo = GlobalFunction::saveFileAndGivePath($request->profile_photo);
            }

            $user->save();

            $token = GlobalFunction::generateUserAuthToken($user);

            $user =  GlobalFunction::prepareUserFullData($user->id);
            // Keep signup successful, but do not trigger the app-side welcome bonus message.
            $user->new_register = false;
            $user->token = $token;
            $user = $this->appendSignupNames($user);
            $user->following_ids = GlobalFunction::fetchUserFollowingIds($user->id);

            return GlobalFunction::sendDataResponse(true,'Data Fetch Successful!', $user);

        } else {
            if (!is_null($normalizedSignupMobile)) {
                $mobileExists = Users::where('user_mobile_no', $normalizedSignupMobile)
                    ->where('id', '!=', intval($user->id))
                    ->exists();
                if ($mobileExists) {
                    return GlobalFunction::sendSimpleResponse(false, 'Mobile number already exists');
                }
            }

            $user->device_token = $request->device_token;
            $user->device = $request->device;
            $user->login_method = $request->login_method;
            if ($request->has('sub_category_id')) {
                $user->sub_category_id = $request->sub_category_id;
                $subCategory = SubCategories::find($request->sub_category_id);
                $user->category_id = $subCategory?->category_id;
            }
            if ($request->has('category_id')) {
                $user->category_id = $request->category_id;
            }
            if ($request->has('topic_id')) {
                $user->topic_id = $request->topic_id;
            }
            if ($request->has('language_id')) {
                $user->language_id = $request->language_id;
            }
            if ($request->has('level_id')) {
                $user->level_id = $request->level_id;
            }
            if ($request->has('is_adult')) {
                $user->is_adult = $request->is_adult;
            }
            if ($request->has('address1')) {
                $user->address1 = $request->address1;
            }
            if ($request->has('address2')) {
                $user->address2 = $request->address2;
            }
            if ($request->has('city')) {
                $user->city = $request->city;
            }
            if ($request->has('state')) {
                $user->state = $request->state;
            }
            if ($request->has('country')) {
                $user->country = $request->country;
            }
            if ($request->has('zipcode')) {
                $user->zipcode = $request->zipcode;
            }
            if (!is_null($normalizedSignupMobile)) {
                $user->user_mobile_no = $normalizedSignupMobile;
            }
            $user->save();

            $token = GlobalFunction::generateUserAuthToken($user);
            $user = GlobalFunction::prepareUserFullData($user->id);
            $user->new_register = false;
            $user->token = $token;
            $user = $this->appendSignupNames($user);
            $user->following_ids = GlobalFunction::fetchUserFollowingIds($user->id);

            return GlobalFunction::sendDataResponse(true, 'Data Fetch Successful!', $user);
        }
    }

    public function requestScreenshotDisable(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $validator = Validator::make($request->all(), [
            'reason' => 'required|string|max:1000',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $reason = trim((string) $request->reason);
        if ($reason === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Reason is required');
        }

        $existingPending = ScreenshotDisableRequest::where('user_id', intval($user->id))
            ->where('status', 0)
            ->first();
        if ($existingPending) {
            return GlobalFunction::sendSimpleResponse(false, 'You already have a pending request');
        }

        $item = new ScreenshotDisableRequest();
        $item->user_id = intval($user->id);
        $item->reason = $reason;
        $item->status = 0;
        $item->save();

        return GlobalFunction::sendDataResponse(true, 'Screenshot disable request submitted successfully', [
            'request_id' => intval($item->id),
            'user_id' => intval($item->user_id),
            'reason' => $item->reason,
            'status' => intval($item->status),
        ]);
    }

    public function approveScreenshotDisableRequestApi(Request $request)
    {
        $token = $request->header('authtoken');
        $approver = GlobalFunction::getUserFromAuthToken($token);
        if (!$approver) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($approver->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $validator = Validator::make($request->all(), [
            'request_id' => 'required|exists:tbl_screenshot_disable_requests,id',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $item = ScreenshotDisableRequest::find(intval($request->request_id));
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'Request not found');
        }
        if (intval($item->status) === 1) {
            return GlobalFunction::sendSimpleResponse(false, 'Request already approved');
        }

        $item->status = 1;
        $item->approved_by = intval($approver->id);
        $item->approved_at = Carbon::now();
        $item->save();

        return GlobalFunction::sendDataResponse(true, 'Screenshot disable request approved successfully', [
            'request_id' => intval($item->id),
            'status' => intval($item->status),
            'approved_by' => intval($item->approved_by),
            'approved_at' => $item->approved_at,
        ]);
    }
    function logInFakeUser(Request $request){
        $validator = Validator::make($request->all(), [
            'identity' => 'required',
            'password' => 'required',
            'device_token' => 'required',
            'device' => 'required',
            'login_method' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $user = Users::where('identity', $request->identity)
        ->where('password', $request->password)
        ->where('is_dummy', 1)
        ->first();

        if ($user != null) {
            $user->device_token = $request->device_token;
            $user->device = $request->device;
            $user->login_method = $request->login_method;
            $user->save();

            $token = GlobalFunction::generateUserAuthToken($user);

            $user =  GlobalFunction::prepareUserFullData($user->id);
            $user->new_register = false;
            $user->token = $token;

            $user->following_ids = GlobalFunction::fetchUserFollowingIds($user->id);

            return GlobalFunction::sendDataResponse(true,'Data Fetch Successful!', $user);

        } else {
            return GlobalFunction::sendSimpleResponse(false, 'Invalid Credentials');
        }
    }
    function logOutUser(Request $request){
        // Validate user token and fetch user
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        $user->device_token = null;
        $authToken = UserAuthTokens::where('user_id', $user->id)->first();
        $authToken->delete();
        $user->save();
        return GlobalFunction::sendSimpleResponse(true, 'Log out Successful!');
    }
}
