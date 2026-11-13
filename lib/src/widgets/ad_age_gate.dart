import 'package:flutter/material.dart';

import '../services/ad_service.dart';

/// In production, avoid ad requests for anyone who may be below the age of
/// consent. This is self-declaration, not age verification; no DOB is stored.
Future<bool> confirmAdAge(BuildContext context, RewardedAdGateway ads) async {
  if (ads.needsAdultConfirmation) {
    final isAdult = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Age confirmation'),
        content: const Text('Are you 18 or older? Players under 18 can play without watching ads.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Under 18')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('18 or older')),
        ],
      ),
    );
    if (isAdult == null) return false;
    ads.recordAdultConfirmation(isAdult);
  }
  return !ads.adsBlockedForAge;
}
