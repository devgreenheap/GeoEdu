<?php

namespace App\Http\Middleware;

use App\Models\UserAuthTokens;
use App\Models\Users;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class AuthorizeUser
{
    private function resolveAuthToken(Request $request): ?string
    {
        $candidates = [
            $_SERVER['HTTP_AUTHTOKEN'] ?? null,
            $_SERVER['HTTP_AUTH_TOKEN'] ?? null,
            $_SERVER['HTTP_AUTHORIZATION'] ?? null,
            $request->header('AUTHTOKEN'),
            $request->header('authtoken'),
            $request->header('Auth-Token'),
            $request->header('auth-token'),
            $request->header('auth_token'),
            $request->header('AUTH_TOKEN'),
            $request->bearerToken() ? ('Bearer ' . $request->bearerToken()) : null,
        ];

        foreach ($candidates as $value) {
            $token = trim((string) ($value ?? ''));
            if ($token === '') {
                continue;
            }
            if (stripos($token, 'Bearer ') === 0) {
                $token = trim(substr($token, 7));
            }
            if ($token !== '') {
                return $token;
            }
        }

        return null;
    }

    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
    public function handle(Request $request, Closure $next)
    {
        $authToken = $this->resolveAuthToken($request);
        if (!$authToken) {
            $data['status']    = false;
            $data['message'] = "Unauthorized Access";
            $data['reason'] = "Token Not Provided";
            return new JsonResponse($data, 401);
        }

        $token = UserAuthTokens::where('auth_token', $authToken)->first();
        if ($token == null) {
            $data['status']    = false;
            $data['message'] = "Unauthorized Access";
            $data['reason'] = "Invalid Token!";
            return new JsonResponse($data, 401);
        }

        // Keep backward compatibility for controllers reading `authtoken`.
        $request->headers->set('authtoken', $authToken);
        $_SERVER['HTTP_AUTHTOKEN'] = $authToken;

        return $next($request);
    }
}
