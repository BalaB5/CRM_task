import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_constants.dart';

extension SizedboxEntension on double {
  Widget get spaceHeight => SizedBox(height: this);

  Widget get spaceWidth => SizedBox(width: this);
}

extension PaddingExtension on double {
  EdgeInsets get paddingAll => EdgeInsets.all(this);

  EdgeInsets get paddingHorizontal => EdgeInsets.symmetric(horizontal: this);

  EdgeInsets get paddingVertical => EdgeInsets.symmetric(vertical: this);
}

extension BorderRadiusExtension on double {
  BorderRadius get radiusAll => BorderRadius.all(Radius.circular(this));
}

extension Type on Object? {
  Map<String, dynamic> get asMap => this as Map<String, dynamic>;
}

extension ShowSnackBar on String? {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? get showSnackBar {
    AppConstants.scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    return AppConstants.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(this ?? ''),
        duration: const Duration(milliseconds: 3000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
extension DateFormatting on DateTime? {
  String get formattedTime {
    if (this == null) return '';
    return DateFormat('hh:mma dd-MM-yyyy').format(this!).toLowerCase();
  }

  String get humanReadableDate {
    if (this == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(this!.year, this!.month, this!.day);

    if (messageDay == today) {
      return 'Today';
    } else if (messageDay == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDay).inDays < 7) {
      return DateFormat('EEEE').format(this!); 
    } else {
      return DateFormat('MMM dd, yyyy').format(this!);
    }
  }
}