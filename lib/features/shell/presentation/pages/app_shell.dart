import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../offers/presentation/pages/offers_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../trips/presentation/pages/trips_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final Set<int> _loadedTabs = {0};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          const HomePage(),
          _loadedTabs.contains(1) ? const TripsPage() : const SizedBox.shrink(),
          _loadedTabs.contains(2) ? const OffersPage() : const SizedBox.shrink(),
          _loadedTabs.contains(3) ? const ProfilePage() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
            _loadedTabs.add(value);
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: context.tr('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.card_travel_outlined),
            selectedIcon: const Icon(Icons.card_travel_rounded),
            label: context.tr('trips'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_offer_outlined),
            selectedIcon: const Icon(Icons.local_offer_rounded),
            label: context.tr('offers'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: context.tr('profile'),
          ),
        ],
      ),
    );
  }
}
