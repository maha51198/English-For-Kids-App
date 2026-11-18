import 'package:flutter/material.dart';
import '../models/models.dart';

const List<String> _levelNames = [
  'المستوى الأول',
  'المستوى الثاني',
  'المستوى الثالث',
  'المستوى الرابع',
  'المستوى الخامس',
  'المستوى السادس',
];

List<Level> _mkLevels(List<WordPair> pairs, List<int> sizes) {
  final out = <Level>[];
  var i = 0;
  for (var idx = 0; idx < sizes.length; idx++) {
    if (i >= pairs.length) break;
    final end = (i + sizes[idx]).clamp(0, pairs.length);
    out.add(Level(
      name: idx < _levelNames.length ? _levelNames[idx] : 'المستوى ${idx + 1}',
      pairs: pairs.sublist(i, end),
    ));
    i = end;
  }
  return out;
}

WordPair _p(String en, String ar, String vis) =>
    WordPair(en: en, ar: ar, visual: vis);

/* ================== LETTERS (26) ================== */
final List<WordPair> _letters = [
  for (final c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))
    _p(c, 'حرف $c', c.toLowerCase()),
];

/* ================== NUMBERS (30) ================== */
final List<WordPair> _numbers = [
  _p('one', 'واحد', '1'),
  _p('two', 'اثنان', '2'),
  _p('three', 'ثلاثة', '3'),
  _p('four', 'أربعة', '4'),
  _p('five', 'خمسة', '5'),
  _p('six', 'ستة', '6'),
  _p('seven', 'سبعة', '7'),
  _p('eight', 'ثمانية', '8'),
  _p('nine', 'تسعة', '9'),
  _p('ten', 'عشرة', '10'),
  _p('eleven', 'أحد عشر', '11'),
  _p('twelve', 'اثنا عشر', '12'),
  _p('thirteen', 'ثلاثة عشر', '13'),
  _p('fourteen', 'أربعة عشر', '14'),
  _p('fifteen', 'خمسة عشر', '15'),
  _p('sixteen', 'ستة عشر', '16'),
  _p('seventeen', 'سبعة عشر', '17'),
  _p('eighteen', 'ثمانية عشر', '18'),
  _p('nineteen', 'تسعة عشر', '19'),
  _p('twenty', 'عشرون', '20'),
  _p('thirty', 'ثلاثون', '30'),
  _p('forty', 'أربعون', '40'),
  _p('fifty', 'خمسون', '50'),
  _p('sixty', 'ستون', '60'),
  _p('seventy', 'سبعون', '70'),
  _p('eighty', 'ثمانون', '80'),
  _p('ninety', 'تسعون', '90'),
  _p('hundred', 'مئة', '100'),
  _p('thousand', 'ألف', '1K'),
  _p('million', 'مليون', '1M'),
];

/* ================== FRUITS (32) ================== */
final List<WordPair> _fruits = [
  _p('apple', 'تفاحة', '🍎'),
  _p('banana', 'موزة', '🍌'),
  _p('orange', 'برتقالة', '🍊'),
  _p('grape', 'عنب', '🍇'),
  _p('lemon', 'ليمون', '🍋'),
  _p('cherry', 'كرز', '🍒'),
  _p('peach', 'خوخ', '🍑'),
  _p('pear', 'كمثرى', '🍐'),
  _p('strawberry', 'فراولة', '🍓'),
  _p('watermelon', 'بطيخ', '🍉'),
  _p('pineapple', 'أناناس', '🍍'),
  _p('mango', 'مانجو', '🥭'),
  _p('kiwi', 'كيوي', '🥝'),
  _p('coconut', 'جوز الهند', '🥥'),
  _p('avocado', 'أفوكادو', '🥑'),
  _p('melon', 'شمام', '🍈'),
  _p('blueberry', 'عنبية', '🫐'),
  _p('olive', 'زيتون', '🫒'),
  _p('apricot', 'مشمش', '🍑'),
  _p('fig', 'تين', '🫒'),
  _p('date', 'تمر', '🌴'),
  _p('pomegranate', 'رمان', '🍎'),
  _p('plum', 'برقوق', '🍑'),
  _p('raspberry', 'توت العليق', '🫐'),
  _p('blackberry', 'توت أسود', '🫐'),
  _p('papaya', 'باباي', '🥭'),
  _p('guava', 'جوافة', '🍐'),
  _p('lime', 'ليمون أخضر', '🍋'),
  _p('tangerine', 'يوسفي', '🍊'),
  _p('grapefruit', 'جريب فروت', '🍊'),
  _p('cranberry', 'توت بري', '🫐'),
  _p('lychee', 'ليتشي', '🍒'),
];

/* ================== VEGETABLES (32) ================== */
final List<WordPair> _veggies = [
  _p('carrot', 'جزرة', '🥕'),
  _p('potato', 'بطاطس', '🥔'),
  _p('onion', 'بصلة', '🧅'),
  _p('garlic', 'ثوم', '🧄'),
  _p('cucumber', 'خيار', '🥒'),
  _p('corn', 'ذرة', '🌽'),
  _p('mushroom', 'فطر', '🍄'),
  _p('broccoli', 'بروكلي', '🥦'),
  _p('eggplant', 'باذنجان', '🍆'),
  _p('lettuce', 'خس', '🥬'),
  _p('pea', 'بازلاء', '🫛'),
  _p('pumpkin', 'قرع', '🎃'),
  _p('bell pepper', 'فلفل حلو', '🫑'),
  _p('chili', 'فلفل حار', '🌶️'),
  _p('ginger', 'زنجبيل', '🫚'),
  _p('sweet potato', 'بطاطا حلوة', '🍠'),
  _p('tomato', 'طماطم', '🍅'),
  _p('cabbage', 'ملفوف', '🥬'),
  _p('celery', 'كرفس', '🥬'),
  _p('spinach', 'سبانخ', '🥬'),
  _p('kale', 'كرنب أجعد', '🥬'),
  _p('radish', 'فجل', '🥕'),
  _p('beet', 'شمندر', '🍠'),
  _p('turnip', 'لفت', '🥔'),
  _p('cauliflower', 'قرنبيط', '🥦'),
  _p('zucchini', 'كوسا', '🥒'),
  _p('asparagus', 'هليون', '🌿'),
  _p('leek', 'كراث', '🥬'),
  _p('parsley', 'بقدونس', '🌿'),
  _p('mint', 'نعنع', '🌿'),
  _p('basil', 'ريحان', '🌿'),
  _p('okra', 'بامية', '🌿'),
];

/* ================== CLOTHES (32) ================== */
final List<WordPair> _clothes = [
  _p('shirt', 'قميص', '👕'),
  _p('dress', 'فستان', '👗'),
  _p('pants', 'بنطال', '👖'),
  _p('shoe', 'حذاء', '👟'),
  _p('boot', 'حذاء طويل', '👢'),
  _p('hat', 'قبعة', '👒'),
  _p('cap', 'كاب', '🧢'),
  _p('sock', 'جورب', '🧦'),
  _p('glove', 'قفاز', '🧤'),
  _p('scarf', 'وشاح', '🧣'),
  _p('coat', 'معطف', '🧥'),
  _p('tie', 'ربطة عنق', '👔'),
  _p('shorts', 'شورت', '🩳'),
  _p('swimsuit', 'لباس سباحة', '🩱'),
  _p('sandal', 'صندل', '🩴'),
  _p('kimono', 'كيمونو', '👘'),
  _p('handbag', 'حقيبة يد', '👜'),
  _p('crown', 'تاج', '👑'),
  _p('jacket', 'جاكيت', '🧥'),
  _p('sweater', 'كنزة', '🧶'),
  _p('hoodie', 'هودي', '🧥'),
  _p('blouse', 'بلوزة', '👚'),
  _p('skirt', 'تنورة', '👗'),
  _p('jeans', 'جينز', '👖'),
  _p('vest', 'سترة', '🦺'),
  _p('apron', 'مريول', '🧵'),
  _p('pajamas', 'بيجاما', '🩱'),
  _p('robe', 'روب', '🥻'),
  _p('belt', 'حزام', '🎗️'),
  _p('wallet', 'محفظة', '👛'),
  _p('sunglasses', 'نظارات شمسية', '🕶️'),
  _p('umbrella', 'مظلة', '☂️'),
];

/* ================== BODY PARTS (30) ================== */
final List<WordPair> _body = [
  _p('head', 'رأس', '🧠'),
  _p('face', 'وجه', '😊'),
  _p('eye', 'عين', '👁️'),
  _p('ear', 'أذن', '👂'),
  _p('nose', 'أنف', '👃'),
  _p('mouth', 'فم', '👄'),
  _p('chin', 'ذقن', '🙂'),
  _p('cheek', 'وجنة', '😊'),
  _p('forehead', 'جبهة', '🧑'),
  _p('neck', 'رقبة', '🧣'),
  _p('shoulder', 'كتف', '💪'),
  _p('chest', 'صدر', '🫁'),
  _p('back', 'ظهر', '🧍'),
  _p('stomach', 'معدة', '🫃'),
  _p('waist', 'خصر', '🧍'),
  _p('hip', 'ورك', '🦵'),
  _p('arm', 'ذراع', '💪'),
  _p('elbow', 'كوع', '💪'),
  _p('wrist', 'معصم', '✋'),
  _p('hand', 'يد', '✋'),
  _p('finger', 'إصبع', '👆'),
  _p('thumb', 'إبهام', '👍'),
  _p('leg', 'ساق', '🦵'),
  _p('knee', 'ركبة', '🦵'),
  _p('ankle', 'كاحل', '🦶'),
  _p('foot', 'قدم', '🦶'),
  _p('toe', 'إصبع القدم', '🦶'),
  _p('skin', 'جلد', '🖐️'),
  _p('bone', 'عظمة', '🦴'),
  _p('heart', 'قلب', '🫀'),
];

/* ================== ANIMALS (32) ================== */
final List<WordPair> _animals = [
  _p('cat', 'قطة', '🐱'),
  _p('dog', 'كلب', '🐶'),
  _p('bird', 'طائر', '🐦'),
  _p('fish', 'سمكة', '🐟'),
  _p('horse', 'حصان', '🐴'),
  _p('cow', 'بقرة', '🐮'),
  _p('pig', 'خنزير', '🐷'),
  _p('sheep', 'خروف', '🐑'),
  _p('rabbit', 'أرنب', '🐰'),
  _p('lion', 'أسد', '🦁'),
  _p('tiger', 'نمر', '🐯'),
  _p('elephant', 'فيل', '🐘'),
  _p('monkey', 'قرد', '🐵'),
  _p('bear', 'دب', '🐻'),
  _p('mouse', 'فأر', '🐭'),
  _p('duck', 'بطة', '🦆'),
  _p('chicken', 'دجاجة', '🐔'),
  _p('frog', 'ضفدع', '🐸'),
  _p('giraffe', 'زرافة', '🦒'),
  _p('zebra', 'حمار وحشي', '🦓'),
  _p('wolf', 'ذئب', '🐺'),
  _p('fox', 'ثعلب', '🦊'),
  _p('deer', 'غزال', '🦌'),
  _p('squirrel', 'سنجاب', '🐿️'),
  _p('hedgehog', 'قنفذ', '🦔'),
  _p('bat', 'خفاش', '🦇'),
  _p('whale', 'حوت', '🐋'),
  _p('dolphin', 'دلفين', '🐬'),
  _p('shark', 'قرش', '🦈'),
  _p('octopus', 'أخطبوط', '🐙'),
  _p('crab', 'سرطان', '🦀'),
  _p('turtle', 'سلحفاة', '🐢'),
];

/* ================== DAYS OF THE WEEK (7) ================== */
final List<WordPair> _days = [
  _p('Sunday', 'الأحد', 'Sun'),
  _p('Monday', 'الاثنين', 'Mon'),
  _p('Tuesday', 'الثلاثاء', 'Tue'),
  _p('Wednesday', 'الأربعاء', 'Wed'),
  _p('Thursday', 'الخميس', 'Thu'),
  _p('Friday', 'الجمعة', 'Fri'),
  _p('Saturday', 'السبت', 'Sat'),
];

/* ================== MONTHS (12) ================== */
final List<WordPair> _months = [
  _p('January', 'يناير', 'Jan'),
  _p('February', 'فبراير', 'Feb'),
  _p('March', 'مارس', 'Mar'),
  _p('April', 'أبريل', 'Apr'),
  _p('May', 'مايو', 'May'),
  _p('June', 'يونيو', 'Jun'),
  _p('July', 'يوليو', 'Jul'),
  _p('August', 'أغسطس', 'Aug'),
  _p('September', 'سبتمبر', 'Sep'),
  _p('October', 'أكتوبر', 'Oct'),
  _p('November', 'نوفمبر', 'Nov'),
  _p('December', 'ديسمبر', 'Dec'),
];

/* ================== SUBJECT PRONOUNS (7) ================== */
final List<WordPair> _pronouns = [
  _p('I', 'أنا', '👤'),
  _p('You', 'أنتَ / أنتِ', '👥'),
  _p('He', 'هو', '👨'),
  _p('She', 'هي', '👩'),
  _p('It', 'هو / هي (لغير العاقل)', '📦'),
  _p('We', 'نحن', '🧑‍🤝‍🧑'),
  _p('They', 'هم', '👨‍👩‍👧‍👦'),
];

/* ================== CATEGORIES ================== */
final List<Category> categories = [
  Category(
    id: 'letters',
    title: 'الحروف',
    sub: 'Letters',
    icon: '🔤',
    color: const Color(0xFF818CF8),
    levels: _mkLevels(_letters, [3, 4, 5, 6, 8]),
  ),
  Category(
    id: 'fruits',
    title: 'الفواكه',
    sub: 'Fruits',
    icon: '🍎',
    color: const Color(0xFFFB7185),
    levels: _mkLevels(_fruits, [3, 4, 5, 6, 7, 7]),
  ),
  Category(
    id: 'numbers',
    title: 'الأرقام',
    sub: 'Numbers',
    icon: '🔢',
    color: const Color(0xFF38BDF8),
    levels: _mkLevels(_numbers, [3, 4, 5, 6, 6, 6]),
  ),
  Category(
    id: 'veggies',
    title: 'الخضار',
    sub: 'Vegetables',
    icon: '🥕',
    color: const Color(0xFF34D399),
    levels: _mkLevels(_veggies, [3, 4, 5, 6, 7, 7]),
  ),
  Category(
    id: 'clothes',
    title: 'الثياب',
    sub: 'Clothes',
    icon: '👕',
    color: const Color(0xFFFBBF24),
    levels: _mkLevels(_clothes, [3, 4, 5, 6, 7, 7]),
  ),
  Category(
    id: 'body',
    title: 'أعضاء الجسم',
    sub: 'Body Parts',
    icon: '🖐️',
    color: const Color(0xFFF472B6),
    levels: _mkLevels(_body, [3, 4, 5, 6, 6, 6]),
  ),
  Category(
    id: 'animals',
    title: 'الحيوانات',
    sub: 'Animals',
    icon: '🦁',
    color: const Color(0xFFA78BFA),
    levels: _mkLevels(_animals, [3, 4, 5, 6, 7, 7]),
  ),
  Category(
    id: 'days',
    title: 'أيام الأسبوع',
    sub: 'Days of the Week',
    icon: '📅',
    color: const Color(0xFFF59E0B),
    levels: _mkLevels(_days, [3, 4]),
  ),
  Category(
    id: 'months',
    title: 'الأشهر',
    sub: 'Months',
    icon: '🗓️',
    color: const Color(0xFF14B8A6),
    levels: _mkLevels(_months, [3, 4, 5]),
  ),
  Category(
    id: 'pronouns',
    title: 'الضمائر',
    sub: 'Subject Pronouns',
    icon: '👤',
    color: const Color(0xFFEF4444),
    levels: _mkLevels(_pronouns, [3, 4]),
  ),
];