import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';

class PickImageWidget extends StatelessWidget {
  const PickImageWidget({super.key, this.pickedImage, required this.function});
  final XFile? pickedImage;
  final Function function;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          function();
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xffffeff6),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 22,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: pickedImage == null
                    ? const Icon(
                        Icons.person_outline_rounded,
                        size: 44,
                        color: AppColors.darkPrimary,
                      )
                    : Image.file(
                        File(pickedImage!.path),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.darkPrimary,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 17,
                  color: Colors.white,
                ),
              ),
            ),
            if (pickedImage == null)
              Positioned(
                left: 0,
                right: 0,
                bottom: -28,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      "Add photo",
                      style: TextStyle(
                        color: AppColors.darkPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
