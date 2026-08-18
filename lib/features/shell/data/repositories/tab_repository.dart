import '../../domain/entities/app_tab.dart';

class TabRepository {
  const TabRepository();
  List<AppTab> get tabs => AppTab.values;
}
