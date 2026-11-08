import 'package:flutter/material.dart';
import 'package:wordnest/src/state/settings_state.dart';

/// Checks if reduced motion mode is enabled.
/// Returns true if the user has reduced motion enabled or if system animations are disabled.
bool fxReduced(BuildContext context) {
  return SettingsState.instance.reduceMotion || MediaQuery.of(context).disableAnimations;
}