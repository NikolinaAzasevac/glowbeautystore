import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glow_beauty_store/services/assets_manager.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class MyAppFunctions {
  static Future<bool> requireSignedIn({
    required BuildContext context,
    String subtitle =
        "Please sign in to use this feature. Guests can browse products only.",
  }) async {
    if (FirebaseAuth.instance.currentUser != null) {
      return true;
    }

    await showErrorOrWarningDialog(
      context: context,
      subtitle: subtitle,
      isError: false,
      fct: () {
        Future<void>.microtask(() {
          if (context.mounted) {
            Navigator.pushNamed(context, "/LoginScreen");
          }
        });
      },
    );
    return false;
  }

  static Future<void> showErrorOrWarningDialog({
    required BuildContext context,
    required String subtitle,
    bool isError = true,
    required Function fct,
  }) async {
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  isError
                      ? "${AssetsManager.imagePath}/warning.png"
                      : "${AssetsManager.imagePath}/caution.png",
                  height: 60,
                  width: 60,
                ),
                const SizedBox(
                  height: 16.0,
                ),
                SubtitleTextWidget(
                  label: subtitle,
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(
                  height: 16.0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Visibility(
                      visible: !isError,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const SubtitleTextWidget(
                          label: "Cancel",
                          color: Colors.green,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        fct();
                        Navigator.pop(context);
                      },
                      child: const SubtitleTextWidget(
                        label: "OK",
                        color: Colors.red,
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        });
  }

  static Future<void> imagePickerDialog({
    required BuildContext context,
    required Function cameraFCT,
    required Function galleryFCT,
    required Function removeFCT,
  }) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Center(
              child: TitelesTextWidget(
                label: "Choose option",
              ),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      cameraFCT();
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.camera),
                    label: const Text("Camera"),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      galleryFCT();
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(
                      Icons.browse_gallery,
                    ),
                    label: const Text("Gallery"),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      removeFCT();
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(
                      Icons.remove_circle_outline,
                    ),
                    label: const Text("Remove"),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
