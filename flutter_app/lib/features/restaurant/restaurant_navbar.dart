// features/restaurant/restaurant_navbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/network/dio_client.dart';
import 'package:flutter_app/data/models/restaurant_model.dart';
import 'package:flutter_app/data/services/restaurant/restaurant_service.dart';
import 'package:flutter_app/features/restaurant/account_management.dart';
import 'package:flutter_app/global_data.dart';

class RestaurantNavbar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const RestaurantNavbar({super.key, required this.title});

  // 🎯 เปลี่ยนธีมสีเป็นสีเขียว
  static const Color primaryGreen = Color(0xFF00B300);
  static const Color greenSoft = Color(0xFFE8F5E9);

  static const double gap = 10;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  State<RestaurantNavbar> createState() => _RestaurantNavbarState();
}

class _RestaurantNavbarState extends State<RestaurantNavbar> {
  final RestaurantService restaurantService = RestaurantService();
  RestaurantModel? restaurantModel;
  String? restaurantImage;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future _loadRestaurantData() async {
    try {
      final rest = await restaurantService.getRestaurantByUsername(
        GlobalData.usernameRestaurant,
      );
      if (!mounted) return;
      setState(() {
        if (rest != null) {
          restaurantModel = rest;
          restaurantImage = rest.restaurantImage;
        }
        _isLoadingProfile = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  String _getFinalImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return "";
    if (rawPath.startsWith('http')) return rawPath;
    final baseUrl = DioClient.dio.options.baseUrl;
    return rawPath.startsWith('/')
        ? "\(baseUrl\)rawPath"
        : "\(baseUrl/\)rawPath";
  }

  @override
  Widget build(BuildContext context) {
    const gap = RestaurantNavbar.gap;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight + 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _HomeButton(
                  onTap: () {
                    final isFirst = ModalRoute.of(context)?.isFirst ?? false;
                    if (isFirst) {
                      final scrollController = PrimaryScrollController.maybeOf(
                        context,
                      );
                      if (scrollController != null &&
                          scrollController.hasClients) {
                        scrollController.animateTo(
                          0.0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    } else {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
                ),
                const SizedBox(width: gap + 4),
                Expanded(
                  child: Text(
                    widget.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F1F),
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const SizedBox(width: gap),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountManagement(),
                    ),
                  ),
                  child: _ProfileAvatar(
                    isLoading: _isLoadingProfile,
                    imageUrl: _getFinalImageUrl(restaurantImage),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HomeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RestaurantNavbar.greenSoft,
      // 🎯 เปลี่ยนเป็นทรงกลมและเอากรอบสี่เหลี่ยมออก
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        splashColor: RestaurantNavbar.primaryGreen.withOpacity(0.18),
        highlightColor: RestaurantNavbar.primaryGreen.withOpacity(0.08),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: const Icon(
            Icons.home_rounded,
            color: RestaurantNavbar.primaryGreen,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final bool isLoading;
  final String imageUrl;
  const _ProfileAvatar({required this.isLoading, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: RestaurantNavbar.primaryGreen,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            RestaurantNavbar.primaryGreen,
            RestaurantNavbar.primaryGreen.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: RestaurantNavbar.primaryGreen.withOpacity(0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: RestaurantNavbar.greenSoft,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person_outline_rounded,
                    color: RestaurantNavbar.primaryGreen,
                    size: 18,
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: RestaurantNavbar.primaryGreen,
                        ),
                      ),
                    );
                  },
                )
              : const Icon(
                  Icons.person_outline_rounded,
                  color: RestaurantNavbar.primaryGreen,
                  size: 18,
                ),
        ),
      ),
    );
  }
}
