import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawadda/core/constants/app_strings.dart';
import 'package:mawadda/core/constants/app_colors.dart';

void main() {
  testWidgets('RTL Arabic text and branding smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.appName),
                  Text(AppStrings.appTagline),
                  Icon(Icons.favorite_rounded, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.appTagline), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });
}
