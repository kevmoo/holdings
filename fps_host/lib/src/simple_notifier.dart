// Avoiding the lint about calling `notifyListeners` being protected/test only.
import 'package:flutter/foundation.dart';

final class SimpleNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
