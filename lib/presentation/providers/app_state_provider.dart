import 'package:flutter/material.dart';

enum AppTab {
  dashboard,
  recharge,
  smsInbox,
  history,
  customers,
  reports,
  debugConsole,
  settings,
  license,
  usbCheck,
}

class AppStateProvider extends ChangeNotifier {
  AppTab _activeTab = AppTab.dashboard;
  bool _isSidebarCollapsed = false;

  AppTab get activeTab => _activeTab;
  bool get isSidebarCollapsed => _isSidebarCollapsed;

  void setActiveTab(AppTab tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
    }
  }

  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }
}
