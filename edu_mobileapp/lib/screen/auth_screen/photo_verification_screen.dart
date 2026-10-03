import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geoedu/common/controller/base_controller.dart';
import 'package:geoedu/common/manager/logger.dart';
import 'package:geoedu/common/manager/session_manager.dart';
import 'package:geoedu/common/service/api/common_service.dart';
import 'package:geoedu/common/service/api/user_service.dart';
import 'package:geoedu/model/user_model/user_model.dart' as user;
import 'package:geoedu/screen/auth_screen/interest_category_screen.dart';
import 'package:geoedu/utilities/color_res.dart';
import 'package:geoedu/utilities/font_res.dart';

class PhotoVerificationScreen extends StatefulWidget {
  final user.User? userData;

  const PhotoVerificationScreen({super.key, this.userData});

  @override
  State<PhotoVerificationScreen> createState() => _PhotoVerificationScreenState();
}

class _PhotoVerificationScreenState extends State<PhotoVerificationScreen> {
  XFile? _capturedPhoto;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _capturedPhoto = photo;
        });
      }
    } catch (e) {
      BaseController.share.showSnackBar('Unable to open camera: ${e.toString()}');
    }
  }

  Future<void> _submitPhoto() async {
    if (_capturedPhoto == null) {
      BaseController.share.showSnackBar('Please capture your verification photo first');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. Upload photo to server storage to get permanent path
      String? uploadedPath;
      try {
        final uploadRes = await CommonService.instance.uploadFileGivePath(_capturedPhoto!);
        if (uploadRes.status == true && uploadRes.data != null && uploadRes.data!.isNotEmpty) {
          uploadedPath = uploadRes.data;
        }
      } catch (uploadErr) {
        Loggers.error('Upload verification photo file error: $uploadErr');
      }

      // 2. Call updateUserDetails with both the file and the server path (if available)
      final user.User? updated = await UserService.instance.updateUserDetails(
        verificationPhoto: _capturedPhoto,
        verificationPhotoPath: uploadedPath,
      );

      // 3. Confirm we have a valid updated user or fetch fresh user from server
      user.User? finalUser = updated;
      if (finalUser == null || (finalUser.verificationPhoto ?? '').isEmpty) {
        final freshUser = await UserService.instance.fetchUserDetails();
        if (freshUser != null) {
          finalUser = freshUser;
        }
      }

      // If still missing, fallback to session user with the server uploaded path
      finalUser ??= SessionManager.instance.getUser() ?? widget.userData;
      if (finalUser != null && (finalUser.verificationPhoto == null || (finalUser.verificationPhoto ?? '').isEmpty)) {
        if (uploadedPath != null && uploadedPath.isNotEmpty) {
          finalUser.verificationPhoto = uploadedPath;
        }
      }

      // Validate that verification photo is indeed set before allowing through
      if (finalUser?.verificationPhoto == null || (finalUser?.verificationPhoto ?? '').isEmpty) {
        BaseController.share.showSnackBar('Failed to save verification photo. Please try again.');
        return;
      }

      SessionManager.instance.setUser(finalUser);

      BaseController.share.showSnackBar('Verification photo uploaded successfully');

      // Proceed to interest selection
      Get.offAll(() => InterestCategoryScreen(userData: finalUser));
    } catch (e) {
      BaseController.share.showSnackBar('Upload failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          BaseController.share.showSnackBar(
            'Photo verification is required to complete your registration.',
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF101318) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorRes.themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: ColorRes.themeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Verification',
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: FontRes.outFitSemiBold600,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Step required before interest selection',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: FontRes.outFitRegular400,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1),

              // Main Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Privacy Protection Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              color: Color(0xFF10B981),
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '100% Private & Admin-Only',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'This verification photo is securely visible only to admins to verify your account. It will NEVER be shown on your public profile.',
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                      fontSize: 11.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Circle Camera Preview Frame
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow / ripple ring
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  ColorRes.themeColor.withValues(alpha: 0.25),
                                  ColorRes.themeColor.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),

                          // Main Preview Box
                          Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF2F7),
                              border: Border.all(
                                color: _capturedPhoto != null
                                    ? const Color(0xFF10B981)
                                    : ColorRes.themeColor,
                                width: 3.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_capturedPhoto != null
                                          ? const Color(0xFF10B981)
                                          : ColorRes.themeColor)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _capturedPhoto != null
                                  ? Image.file(
                                      File(_capturedPhoto!.path),
                                      fit: BoxFit.cover,
                                      width: 210,
                                      height: 210,
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: ColorRes.themeColor.withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 44,
                                            color: ColorRes.themeColor,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Selfie Camera',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontFamily: FontRes.outFitMedium500,
                                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          // Verified status badge if photo taken
                          if (_capturedPhoto != null)
                            Positioned(
                              bottom: 8,
                              right: 20,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Text(
                        _capturedPhoto == null
                            ? 'Position your face clearly'
                            : 'Selfie captured successfully! 🎉',
                        style: TextStyle(
                          fontSize: 17,
                          fontFamily: FontRes.outFitSemiBold600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _capturedPhoto == null
                              ? 'Make sure you are in a well-lit area with your face fully visible to complete profile verification.'
                              : 'Review your photo. If it is clear and well-lit, tap Submit to proceed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontFamily: FontRes.outFitRegular400,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Take / Retake Button
                      InkWell(
                        onTap: _isUploading ? null : _takePhoto,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _capturedPhoto == null
                                ? ColorRes.themeColor
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(16),
                            border: _capturedPhoto != null
                                ? Border.all(
                                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _capturedPhoto == null
                                    ? Icons.camera_alt_rounded
                                    : Icons.refresh_rounded,
                                color: _capturedPhoto == null
                                    ? Colors.white
                                    : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _capturedPhoto == null ? 'Take Verification Photo' : 'Retake Photo',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: FontRes.outFitSemiBold600,
                                  color: _capturedPhoto == null
                                      ? Colors.white
                                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Submit & Continue Button
                      if (_capturedPhoto != null)
                        InkWell(
                          onTap: _isUploading ? null : _submitPhoto,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            alignment: Alignment.center,
                            child: _isUploading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Submit & Continue',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: FontRes.outFitSemiBold600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
