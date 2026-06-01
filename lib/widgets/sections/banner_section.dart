import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/responsive.dart';
import '../common/primary_button.dart';

class BannerSection extends StatelessWidget {
  const BannerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: mobile ? 20 : 80, vertical: 60),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.asset(
              'assets/images/banners.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
          Positioned(
            right: mobile ? 20 : 40,
            bottom: mobile ? 20 : 40,
            child: PrimaryButton(
              label: 'Começar agora',
              variant: ButtonVariant.orange,
              onPressed: () => context.go('/cadastro'),
            ),
          ),
        ],
      ),
    );
  }
}
