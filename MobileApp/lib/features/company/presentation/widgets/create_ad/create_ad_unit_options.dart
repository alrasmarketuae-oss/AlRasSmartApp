import 'package:alrasmarket/generated/l10n.dart';

class CreateAdUnitOptions {
  CreateAdUnitOptions._();

  static const values = <String>[
    'Ton',
    'Gram',
    'Kg',
    'Carton',
    'Bag',
    'Dozen',
    'Box',
    'Piece',
  ];

  static String localizedLabel(String unit, S s) {
    switch (canonical(unit).toLowerCase()) {
      case 'ton':
        return s.unitTon;
      case 'gram':
        return s.unitGram;
      case 'kg':
        return s.unitKg;
      case 'piece':
        return s.unitPiece;
      case 'carton':
        return s.unitCarton;
      case 'bag':
        return s.unitBag;
      case 'dozen':
        return s.unitDozen;
      case 'box':
        return s.unitBox;
      default:
        return unit;
    }
  }

  /// Maps API/UI/Arabic labels to the English values used in [values].
  static String canonical(String unit) {
    switch (unit.trim().toLowerCase()) {
      case 'ton':
      case 'tons':
      case 'tonne':
      case 'tonnes':
      case 'طن':
      case 'اطنان':
      case 'أطنان':
        return 'Ton';
      case 'gram':
      case 'grams':
      case 'g':
      case 'جرام':
      case 'غرام':
        return 'Gram';
      case 'kg':
      case 'kgs':
      case 'kilo':
      case 'kilos':
      case 'kilogram':
      case 'kilograms':
      case 'كجم':
      case 'كيلو':
      case 'كيلوجرام':
      case 'كيلو جرام':
        return 'Kg';
      case 'piece':
      case 'pieces':
      case 'pc':
      case 'pcs':
      case 'قطعة':
      case 'قطع':
        return 'Piece';
      case 'carton':
      case 'cartons':
      case 'كرتون':
        return 'Carton';
      case 'bag':
      case 'bags':
      case 'كيس':
      case 'أكياس':
      case 'اكياس':
        return 'Bag';
      case 'dozen':
      case 'dozens':
      case 'دزينة':
        return 'Dozen';
      case 'box':
      case 'boxes':
      case 'صندوق':
      case 'صناديق':
        return 'Box';
      default:
        // Preserve known English option casing if already in the list.
        for (final value in values) {
          if (value.toLowerCase() == unit.trim().toLowerCase()) {
            return value;
          }
        }
        return unit.trim();
    }
  }
}
