import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/details/movie_details_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/main_shell.dart';
import '../screens/player/player_screen.dart';
import '../screens/profiles/create_profile_screen.dart';
import '../screens/profiles/profile_selection_screen.dart';
import '../screens/settings/edit_profile_screen.dart';
import '../screens/settings/parental_control_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/trial/trial_welcome_screen.dart';
import '../screens/trial/trial_status_screen.dart';
import '../screens/trial/plans_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

final routes = <String, WidgetBuilder>{
  '/': (_) => const SplashScreen(),
  '/login': (_) => const LoginScreen(),
  '/register': (_) => const RegisterScreen(),
  '/onboarding': (_) => const OnboardingScreen(),
  '/profiles': (_) => const ProfileSelectionScreen(),
  '/create-profile': (_) => const CreateProfileScreen(),
  '/home': (_) => const MainShell(),
  '/details': (_) => const MovieDetailsScreen(),
  '/favorites': (_) => const FavoritesScreen(),
  '/player': (_) => const PlayerScreen(),
  '/settings': (_) => const SettingsScreen(),
  '/edit-profile': (_) => const EditProfileScreen(),
  '/parental': (_) => const ParentalControlScreen(),
  '/trial-welcome': (_) => const TrialWelcomeScreen(),
  '/trial-status': (_) => const TrialStatusScreen(),
  '/plans': (_) => const PlansScreen(),
};
