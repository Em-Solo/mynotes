import 'package:flutter/material.dart' show BuildContext, ModalRoute;

extension GetArguments on BuildContext {
  T? getArgument<T>() {
    // this identifier refers to the build context of the place the funtion was invoked
    // we dont do context because we are in buildcontext so this will refere to the context of the place its called at
    // refers to the context variable it calls it
    final modalRoute = ModalRoute.of(this);
    if (modalRoute != null) {
      final args = modalRoute.settings.arguments;
      if (args != null && args is T) {
        return args as T;
      }
    }
    return null;
  }
}
