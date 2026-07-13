import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:glow_beauty_store/consts/app_colors.dart';
import 'package:glow_beauty_store/models/user_model.dart';
import 'package:glow_beauty_store/providers/theme_provider.dart';
import 'package:glow_beauty_store/providers/user_provider.dart';
import 'package:glow_beauty_store/screens/admin/admin_panel_screen.dart';
import 'package:glow_beauty_store/screens/auth/login.dart';
import 'package:glow_beauty_store/screens/inner_screen/orders/orders_screen.dart';
import 'package:glow_beauty_store/screens/inner_screen/viewed_recently.dart';
import 'package:glow_beauty_store/screens/inner_screen/wishlist.dart';
import 'package:glow_beauty_store/screens/profile/currency_rates_screen.dart';
import 'package:glow_beauty_store/screens/profile/saved_addresses_screen.dart';
import 'package:glow_beauty_store/services/assets_manager.dart';
import 'package:glow_beauty_store/services/my_app_functions.dart';
import 'package:glow_beauty_store/widgets/common/brand_mark.dart';
import 'package:glow_beauty_store/widgets/subtitle_text.dart';
import 'package:glow_beauty_store/widgets/title_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  UserModel? userModel;

  Future<void> fetchUserInfo() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      userModel = await userProvider.fetchUserInfo();
    } catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> _handleAuthAction(User? user) async {
    if (user == null) {
      Navigator.pushNamed(context, LoginScreen.routeName);
      return;
    }

    await MyAppFunctions.showErrorOrWarningDialog(
      context: context,
      subtitle: "Are you sure you want to sign out?",
      isError: false,
      fct: () async {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      },
    );
  }

  Future<void> _updateProfileImage(ImageSource source) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await MyAppFunctions.requireSignedIn(
        context: context,
        subtitle: "Please sign in before changing your profile photo.",
      );
      return;
    }

    try {
      final pickedImage = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 65,
      );
      if (pickedImage == null) {
        return;
      }

      final imageBytes = await pickedImage.readAsBytes();
      final imageUrl = "data:image/jpeg;base64,${base64Encode(imageBytes)}";
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
        "userImage": imageUrl,
      });
      await fetchUserInfo();
    } catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    }
  }

  Future<void> _removeProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
        "userImage": "",
      });
      await fetchUserInfo();
    } catch (error) {
      if (!mounted) return;
      await MyAppFunctions.showErrorOrWarningDialog(
        context: context,
        subtitle: error.toString(),
        fct: () {},
      );
    }
  }

  Future<void> _showProfileImageActions() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await MyAppFunctions.requireSignedIn(
        context: context,
        subtitle: "Please sign in before changing your profile photo.",
      );
      return;
    }

    if (!mounted) return;
    await MyAppFunctions.imagePickerDialog(
      context: context,
      cameraFCT: () => _updateProfileImage(ImageSource.camera),
      galleryFCT: () => _updateProfileImage(ImageSource.gallery),
      removeFCT: _removeProfileImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final hasUserImage =
        userModel != null && userModel!.userImage.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        leadingWidth: 72,
        leading: const Padding(
          padding: EdgeInsets.all(12),
          child: BrandMark(size: 50),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TitelesTextWidget(
              label: "My Profile",
              fontSize: 18,
            ),
            SubtitleTextWidget(
              label: "Account, orders and preferences",
              fontSize: 12,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.darkPrimary,
        onRefresh: fetchUserInfo,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _ProfileHeroCard(
              user: user,
              userModel: userModel,
              hasUserImage: hasUserImage,
              onChangeImage: _showProfileImageActions,
            ),
            const SizedBox(height: 18),
            if (user == null) ...[
              const _GuestInfoCard(),
              const SizedBox(height: 18),
            ],
            _ProfileSection(
              title: "General",
              subtitle: "Everything tied to your shopping journey",
              children: [
                if (userModel?.role.toLowerCase() == 'admin')
                  _ProfileActionTile(
                    icon: Icons.admin_panel_settings_outlined,
                    accentColor: const Color(0xff8a4bb8),
                    text: "Admin Panel",
                    subtitle: "Manage users, products, orders and reviews",
                    onTap: () {
                      Navigator.pushNamed(context, AdminPanelScreen.routeName);
                    },
                  ),
                if (userModel != null)
                  _ProfileActionTile(
                    icon: IconlyLight.bag2,
                    accentColor: const Color(0xffb84f7e),
                    text: "My Orders",
                    subtitle: "Track delivery and review order history",
                    onTap: () {
                      Navigator.pushNamed(context, OrdersScreen.routeName);
                    },
                  ),
                if (userModel != null)
                  _ProfileActionTile(
                    icon: IconlyLight.heart,
                    accentColor: const Color(0xffd95763),
                    text: "Wishlist",
                    subtitle: "Saved products you want to revisit",
                    onTap: () {
                      Navigator.pushNamed(context, WishlistScreen.routeName);
                    },
                  ),
                _ProfileActionTile(
                  icon: IconlyLight.timeCircle,
                  accentColor: const Color(0xff5b6ee1),
                  text: "Viewed Recently",
                  subtitle: "Continue exploring products you opened before",
                  onTap: () {
                    Navigator.pushNamed(
                        context, ViewedRecentlyScreen.routeName);
                  },
                ),
                _ProfileActionTile(
                  icon: Icons.location_on_outlined,
                  accentColor: const Color(0xff2f9d8f),
                  text: "Saved Addresses",
                  subtitle: "Manage checkout addresses and defaults",
                  onTap: () async {
                    final canContinue = await MyAppFunctions.requireSignedIn(
                      context: context,
                      subtitle: "Please sign in before managing addresses.",
                    );
                    if (!canContinue) {
                      return;
                    }
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.pushNamed(
                      context,
                      SavedAddressesScreen.routeName,
                    );
                  },
                ),
                _ProfileActionTile(
                  icon: Icons.currency_exchange_rounded,
                  accentColor: const Color(0xff1f8a70),
                  text: "Currency Rates",
                  subtitle: "Live EUR exchange rates from an external API",
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      CurrencyRatesScreen.routeName,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileSection(
              title: "Settings",
              subtitle: "Keep the experience comfortable for your eyes",
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: SwitchListTile(
                    secondary: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.darkPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Image.asset(
                        "${AssetsManager.imagePath}/profile/night-mode.png",
                        height: 24,
                      ),
                    ),
                    title: Text(
                      themeProvider.getIsDarkTheme
                          ? "Dark Theme"
                          : "Light Theme",
                    ),
                    subtitle: const Text(
                      "Switch between light and dark interface styles.",
                    ),
                    value: themeProvider.getIsDarkTheme,
                    onChanged: (value) {
                      themeProvider.setDarkTheme(themeValue: value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: user == null
                    ? AppColors.darkPrimary
                    : const Color(0xff9b3f63),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: Icon(user == null ? Icons.login : Icons.logout),
              label: Text(user == null ? "Login to continue" : "Logout"),
              onPressed: () => _handleAuthAction(user),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.user,
    required this.userModel,
    required this.hasUserImage,
    required this.onChangeImage,
  });

  final User? user;
  final UserModel? userModel;
  final bool hasUserImage;
  final VoidCallback onChangeImage;

  @override
  Widget build(BuildContext context) {
    final displayName = userModel?.userName ?? 'Glow Guest';
    final displayEmail =
        userModel?.userEmail ?? 'Sign in to sync your orders and wishlist';
    final joinedLabel =
        userModel == null ? 'Guest mode active' : 'Signed in and ready to shop';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xffffeff6),
            Color(0xfff7e7f7),
            Color(0xfffffbfd),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onChangeImage,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.8),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipOval(
                    child: hasUserImage
                        ? _ProfileAvatarImage(image: userModel!.userImage)
                        : const Icon(Icons.person, size: 38),
                  ),
                ),
                if (user != null)
                  Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.darkPrimary,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                      )),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubtitleTextWidget(
                  label: user == null ? "GUEST PROFILE" : "PERSONAL ACCOUNT",
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkPrimary,
                ),
                const SizedBox(height: 8),
                TitelesTextWidget(
                  label: displayName,
                  fontSize: 24,
                ),
                const SizedBox(height: 6),
                SubtitleTextWidget(
                  label: displayEmail,
                  fontSize: 14,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: SubtitleTextWidget(
                    label: joinedLabel,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatarImage extends StatelessWidget {
  const _ProfileAvatarImage({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    if (image.startsWith("data:image")) {
      final base64Data = image.split(",").last;
      return Image.memory(
        base64Decode(base64Data),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 38),
      );
    }

    return Image.network(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 38),
    );
  }
}

class _GuestInfoCard extends StatelessWidget {
  const _GuestInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.darkPrimary,
          ),
          SizedBox(width: 12),
          Expanded(
            child: SubtitleTextWidget(
              label:
                  "Sign in to access your orders, wishlist and saved addresses across devices.",
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitelesTextWidget(
          label: title,
          fontSize: 22,
        ),
        const SizedBox(height: 6),
        SubtitleTextWidget(
          label: subtitle,
          fontSize: 14,
        ),
        const SizedBox(height: 12),
        ...children.map(
          (child) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.accentColor,
    required this.text,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String text;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SubtitleTextWidget(
                    label: text,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  const SizedBox(height: 4),
                  SubtitleTextWidget(
                    label: subtitle,
                    fontSize: 13,
                  ),
                ],
              ),
            ),
            const Icon(IconlyLight.arrowRight2),
          ],
        ),
      ),
    );
  }
}
