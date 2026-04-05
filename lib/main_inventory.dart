import 'core/config/app_mode.dart';
import 'main.dart';

void main() async {
  await bootstrapApp(AppMode.inventoryOnly);
}
