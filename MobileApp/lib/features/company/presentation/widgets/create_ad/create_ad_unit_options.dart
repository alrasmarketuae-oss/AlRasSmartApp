import 'package:alrasmarket/generated/l10n.dart';

class CreateAdUnitOptions {
  CreateAdUnitOptions._();

  /// Display order shown in the create-ad unit dropdown.
  /// 'Kg' is a UI token mapped to the DB unit name 'Kilogram' when submitting.
  static const values = <String>[
    'Ton',
    'Kg',
    'Bag',
    'Carton',
    'Packet',
    'Box',
    'Bundle',
    'Dozen',
    'Drum',
    'Bottle',
    'Tin',
    'Sack',
    'Case',
    'Pallet',
    'Liter',
    'Ml',
    'Gram',
    'Jar',
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
      case 'packet':
        return s.unitPacket;
      case 'bundle':
        return s.unitBundle;
      case 'drum':
        return s.unitDrum;
      case 'bottle':
        return s.unitBottle;
      case 'tin':
        return s.unitTin;
      case 'sack':
        return s.unitSack;
      case 'case':
        return s.unitCase;
      case 'pallet':
        return s.unitPallet;
      case 'liter':
        return s.unitLiter;
      case 'ml':
        return s.unitMl;
      case 'jar':
        return s.unitJar;
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
      case 'قطعه':
      case 'حبة':
      case 'حبه':
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
      case 'packet':
      case 'packets':
      case 'عبوة':
      case 'عبوه':
      case 'باكيت':
        return 'Packet';
      case 'bundle':
      case 'bundles':
      case 'حزمة':
      case 'حزمه':
        return 'Bundle';
      case 'drum':
      case 'drums':
      case 'برميل':
      case 'براميل':
        return 'Drum';
      case 'bottle':
      case 'bottles':
      case 'زجاجة':
      case 'زجاجه':
        return 'Bottle';
      case 'tin':
      case 'tins':
      case 'علبة معدنية':
      case 'علبه معدنيه':
        return 'Tin';
      case 'sack':
      case 'sacks':
      case 'شوال':
        return 'Sack';
      case 'case':
      case 'cases':
      case 'كرتونة':
      case 'كرتونه':
        return 'Case';
      case 'pallet':
      case 'pallets':
      case 'طبلية':
      case 'طبليه':
        return 'Pallet';
      case 'liter':
      case 'liters':
      case 'litre':
      case 'litres':
      case 'لتر':
      case 'لترات':
        return 'Liter';
      case 'ml':
      case 'milliliter':
      case 'milliliters':
      case 'millilitre':
      case 'millilitres':
      case 'ملليلتر':
      case 'ملي':
        return 'Ml';
      case 'jar':
      case 'jars':
      case 'برطمان':
      case 'برطمانات':
        return 'Jar';
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
