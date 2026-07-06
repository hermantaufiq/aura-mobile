import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/avatar_utils.dart';
import '../../models/user_model.dart';

class UserAvatar extends StatelessWidget {
  final UserModel? user;
  final double radius;
  final bool showPremiumBadge;
  final bool isLoading;
  final VoidCallback? onTap;
  final String? heroTag;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 20,
    this.showPremiumBadge = false,
    this.isLoading = false,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final ts = AppTextStyles.of(context);
    final name = user?.name ?? '';
    final id = user?.id ?? 'default';
    final avatarUrl = user != null ? AvatarUtils.avatarUrl(user!) : null;
    final bgColor = AvatarUtils.colorFromId(id);
    final initials = AvatarUtils.getInitials(name);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initialsStyle = radius >= 44
        ? ts.displaySmall
        : radius >= 28
            ? ts.displayMedium
            : ts.headlineSmall;

    Widget avatarContent = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.adaptiveBorder(context),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                httpHeaders: AvatarUtils.authHeaders(),
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
                placeholder: (_, __) => _InitialsView(
                  initials: initials,
                  bgColor: bgColor,
                  radius: radius,
                  textStyle: initialsStyle,
                ),
                errorWidget: (_, __, ___) => _InitialsView(
                  initials: initials,
                  bgColor: bgColor,
                  radius: radius,
                  textStyle: initialsStyle,
                ),
              )
            : _InitialsView(
                initials: initials,
                bgColor: bgColor,
                radius: radius,
                textStyle: initialsStyle,
              ),
      ),
    );

    if (heroTag != null) {
      avatarContent = Hero(tag: heroTag!, child: avatarContent);
    }

    Widget avatar = Semantics(
      label: 'Foto profil $name',
      child: avatarContent,
    );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (showPremiumBadge)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(radius * 0.1),
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: radius * 0.35,
              ),
            ),
          ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white12 : AppColors.adaptiveBorder(context),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InitialsView extends StatelessWidget {
  final String initials;
  final Color bgColor;
  final double radius;
  final TextStyle textStyle;

  const _InitialsView({
    required this.initials,
    required this.bgColor,
    required this.radius,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: bgColor.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: textStyle.copyWith(color: bgColor),
      ),
    );
  }
}
