import 'package:draft_race/ui/theme/app_tokens.dart';
import 'package:draft_race/ui/theme/themes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offered themes are explicit, distinct sports presentations', () {
    expect(AppThemes.all, hasLength(2));
    expect(AppThemes.stadium.name, 'Football Sunday');
    expect(AppThemes.stadium.tokens.sport, SportPresentation.football);
    expect(AppThemes.hardwood.name, 'Basketball Hardwood');
    expect(AppThemes.hardwood.tokens.sport, SportPresentation.basketball);

    expect(AppThemes.stadium.isDark, isTrue);
    expect(AppThemes.hardwood.isDark, isFalse);
    expect(
      AppThemes.stadium.tokens.background,
      isNot(AppThemes.hardwood.tokens.background),
    );
    expect(
      AppThemes.stadium.tokens.turf,
      isNot(AppThemes.hardwood.tokens.turf),
    );
  });
}
