import 'package:lib5/util.dart';

/// A custom logger built for S5 needs.
class S5Logger extends SimpleLogger {
  /// Constructor for S5Logger.
  S5Logger({
    super.prefix = '[S5] ',
    super.format = true,
    super.showVerbose = false,
  });
}
