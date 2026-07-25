// Demo data for testing the app without backend
class DemoData {
  DemoData._();
  // Demo Banners Response
  static const Map<String, dynamic> bannersResponse = {
    'status': true,
    'code': 200,
    'msg': 'Banners loaded successfully (Demo Mode)',
    'data': [
      {
        'id': 1,
        'title_en': 'Special Offers',
        'title_ar': 'عروض خاصة',
        'description_en': 'Check out our amazing deals',
        'description_ar': 'تحقق من عروضنا المذهلة',
        'photo': baner1,
        'link': null,
        'created_at': '2024-01-15 10:00:00',
        'updated_at': '2024-01-15 10:00:00',
      },
      {
        'id': 2,
        'title_en': 'New Arrivals',
        'title_ar': 'وصل حديثاً',
        'description_en': 'Latest products and services',
        'description_ar': 'أحدث المنتجات والخدمات',
        'photo': baner2,
        'link': null,
        'created_at': '2024-01-15 11:00:00',
        'updated_at': '2024-01-15 11:00:00',
      },
      {
        'id': 3,
        'title_en': 'Hot Deals',
        'title_ar': 'صفقات ساخنة',
        'description_en': 'Limited time offers',
        'description_ar': 'عروض لفترة محدودة',
        'photo': baner3,
        'link': null,
        'created_at': '2024-01-15 12:00:00',
        'updated_at': '2024-01-15 12:00:00',
      },
    ],
  };

  // Demo Categories Response
  // Demo banner image URLs
  static const String baner1 =
      'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=800&h=400&fit=crop';
  static const String baner2 =
      'https://images.unsplash.com/photo-1617814076367-b759c7d7e738?w=800&h=400&fit=crop';
  static const String baner3 =
      'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=800&h=400&fit=crop';

  static const Map<String, dynamic> categoriesResponse = {
    'status': true,
    'code': 200,
    'msg': 'Categories loaded successfully (Demo Mode)',
    'data': [
      {
        'id': 1001,
        'title_en': 'Car Sales',
        'title_ar': 'بيع السيارات',
        'key': 'car_sales',
        'photo': 'https://via.placeholder.com/200x200/2C2E83/FFFFFF?text=Cars',
      },
      {
        'id': 1002,
        'title_en': 'Real Estate',
        'title_ar': 'عقارات',
        'key': 'real_estate',
        'photo':
            'https://via.placeholder.com/200x200/4A90E2/FFFFFF?text=Estate',
      },
      {
        'id': 1003,
        'title_en': 'Electronics',
        'title_ar': 'إلكترونيات',
        'key': 'electronics',
        'photo':
            'https://via.placeholder.com/200x200/50C878/FFFFFF?text=Electronics',
      },
      {
        'id': 1004,
        'title_en': 'Jobs',
        'title_ar': 'وظائف',
        'key': 'jobs',
        'photo': 'https://via.placeholder.com/200x200/FF6B6B/FFFFFF?text=Jobs',
      },
      {
        'id': 1005,
        'title_en': 'Car Rental',
        'title_ar': 'تأجير السيارات',
        'key': 'car_rental',
        'photo':
            'https://via.placeholder.com/200x200/FFD93D/FFFFFF?text=Rental',
      },
      {
        'id': 1006,
        'title_en': 'Car Services',
        'title_ar': 'خدمات السيارات',
        'key': 'car_services',
        'photo':
            'https://via.placeholder.com/200x200/A8E6CF/FFFFFF?text=Service',
      },
      {
        'id': 1007,
        'title_en': 'Restaurants',
        'title_ar': 'مطاعم',
        'key': 'restaurants',
        'photo': 'https://via.placeholder.com/200x200/FF8B94/FFFFFF?text=Food',
      },
      {
        'id': 1008,
        'title_en': 'Other Services',
        'title_ar': 'خدمات أخرى',
        'key': 'other_services',
        'photo':
            'https://via.placeholder.com/200x200/C7CEEA/FFFFFF?text=Services',
      },
    ],
  };

  // Demo Posts (Ads)
  // Demo image URLs - Using reliable image sources
  static const String imageAudi =
      'https://d1esl34bhh6pms.cloudfront.net/cars/used/images/original/956ed99d-ac1b-4d38-8df5-508de3132eaa';

  static const String imageBMW =
      'https://ymimg1.b8cdn.com/resized/used_car/2025/10/24/2060940/pictures/15848558/webp_listing_main_BMW_1_Series_2022_in_Dubai_2060940_16.webp';
  static const String imageVilla =
      'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800&h=600&fit=crop';
  static const String imageiPhone =
      'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=800&h=600&fit=crop';
  static const String imageJob =
      'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=800&h=600&fit=crop';
  static const Map<String, dynamic> postsResponse = {
    'status': true,
    'msg': 'Posts loaded successfully (Demo Mode)',
    'data': [
      {
        'id': 1,
        'title': 'Audi A5 Tfsi Quattro 2022',
        'price': 156000,
        'photo': imageAudi,
        'description': 'Excellent condition, full service history, low mileage',
        'category_id': 1001,
        'phone': '+971501234567',
        'whatsapp': '+971501234567',
        'area': 'Dubai',
        'created_at': '2024-11-10 10:00:00',
        'updated_at': '2024-11-10 10:00:00',
        'is_favorite': false,
        'active': true,
        'km': 77899,
        'photos': [
          {
            'id': 1,
            'photo': imageAudi,
            'post_id': 1,
            'created_at': '2024-11-10 10:00:00',
            'updated_at': '2024-11-10 10:00:00',
          },
        ],
        'make': {
          'id': 1,
          'title_en': 'Audi',
          'title_ar': 'أودي',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'model': {
          'id': 1,
          'title_en': 'A5',
          'title_ar': 'إيه 5',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'year': {
          'id': 3,
          'title_en': '2022',
          'title_ar': '2022',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'color': {
          'id': 1,
          'title_en': 'Black',
          'title_ar': 'أسود',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'trans_type': {
          'id': 1,
          'title_en': 'Automatic',
          'title_ar': 'أوتوماتيك',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'fuel_type': {
          'id': 1,
          'title_en': 'Petrol',
          'title_ar': 'بنزين',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'city': {
          'id': 1,
          'title_en': 'Dubai',
          'title_ar': 'دبي',
          'country_id': 1,
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'district': {
          'id': 1,
          'title_en': 'Downtown',
          'title_ar': 'وسط المدينة',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
      },
      {
        'id': 2,
        'title': 'BMW X5 M Sport 2021',
        'price': 175000,
        'photo': imageBMW,
        'description': 'Premium luxury SUV, fully loaded',
        'category_id': 1001,
        'phone': '+971502345678',
        'whatsapp': '+971502345678',
        'area': 'Abu Dhabi',
        'created_at': '2024-11-12 10:00:00',
        'updated_at': '2024-11-12 10:00:00',
        'is_favorite': false,
        'active': true,
        'km': 45200,
        'photos': [
          {
            'id': 2,
            'photo': imageBMW,
            'post_id': 2,
            'created_at': '2024-11-12 10:00:00',
            'updated_at': '2024-11-12 10:00:00',
          },
        ],
        'make': {
          'id': 2,
          'title_en': 'BMW',
          'title_ar': 'بي إم دبليو',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'model': {
          'id': 2,
          'title_en': 'X5',
          'title_ar': 'إكس 5',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'year': {
          'id': 4,
          'title_en': '2021',
          'title_ar': '2021',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'color': {
          'id': 2,
          'title_en': 'White',
          'title_ar': 'أبيض',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'trans_type': {
          'id': 1,
          'title_en': 'Automatic',
          'title_ar': 'أوتوماتيك',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'fuel_type': {
          'id': 2,
          'title_en': 'Diesel',
          'title_ar': 'ديزل',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'city': {
          'id': 2,
          'title_en': 'Abu Dhabi',
          'title_ar': 'أبوظبي',
          'country_id': 1,
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'district': {
          'id': 2,
          'title_en': 'Al Reem Island',
          'title_ar': 'جزيرة الريم',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
      },
      {
        'id': 3,
        'title': 'Luxury Villa in Dubai Marina',
        'price': 2500000,
        'photo': imageVilla,
        'description': '4 bedroom villa with sea view',
        'category_id': 1002,
        'phone': '+971503456789',
        'whatsapp': '+971503456789',
        'area': 'Dubai Marina',
        'created_at': '2024-11-11 10:00:00',
        'updated_at': '2024-11-11 10:00:00',
        'is_favorite': false,
        'active': true,
        'photos': [
          {
            'id': 3,
            'photo': imageVilla,
            'post_id': 3,
            'created_at': '2024-11-11 10:00:00',
            'updated_at': '2024-11-11 10:00:00',
          },
        ],
        'city': {
          'id': 1,
          'title_en': 'Dubai',
          'title_ar': 'دبي',
          'country_id': 1,
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'district': {
          'id': 3,
          'title_en': 'Dubai Marina',
          'title_ar': 'دبي مارينا',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
      },
      {
        'id': 4,
        'title': 'iPhone 15 Pro Max 256GB',
        'price': 4500,
        'photo': imageiPhone,
        'description': 'Brand new, sealed, with warranty',
        'category_id': 1003,
        'phone': '+971504567890',
        'whatsapp': '+971504567890',
        'area': 'Sharjah',
        'created_at': '2024-11-13 10:00:00',
        'updated_at': '2024-11-13 10:00:00',
        'is_favorite': false,
        'active': true,
        'photos': [
          {
            'id': 4,
            'photo': imageiPhone,
            'post_id': 4,
            'created_at': '2024-11-13 10:00:00',
            'updated_at': '2024-11-13 10:00:00',
          },
        ],
        'city': {
          'id': 3,
          'title_en': 'Sharjah',
          'title_ar': 'الشارقة',
          'country_id': 1,
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'district': {
          'id': 4,
          'title_en': 'Al Nahda',
          'title_ar': 'النهدة',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
      },
      {
        'id': 5,
        'title': 'Senior Flutter Developer',
        'price': 15000,
        'photo': imageJob,
        'description': '3+ years experience required',
        'category_id': 1004,
        'phone': '+971505678901',
        'whatsapp': '+971505678901',
        'area': 'Dubai',
        'created_at': '2024-11-14 10:00:00',
        'updated_at': '2024-11-14 10:00:00',
        'is_favorite': false,
        'active': true,
        'photos': [
          {
            'id': 5,
            'photo': imageJob,
            'post_id': 5,
            'created_at': '2024-11-14 10:00:00',
            'updated_at': '2024-11-14 10:00:00',
          },
        ],
        'city': {
          'id': 1,
          'title_en': 'Dubai',
          'title_ar': 'دبي',
          'country_id': 1,
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        'district': {
          'id': 5,
          'title_en': 'Business Bay',
          'title_ar': 'الخليج التجاري',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
      },
    ],
  };

  // Demo Top Clients Posts - Returns data grouped by client
  static List<Map<String, dynamic>> getTopClientsPosts(int categoryId) {
    // Filter posts by category
    final categoryPosts =
        (postsResponse['data'] as List)
            .where((post) => post['category_id'] == categoryId)
            .toList();

    if (categoryPosts.isEmpty) {
      return [];
    }

    // Group posts by a demo client
    return [
      {
        'client': {
          'id': 1,
          'name': 'Premium Auto Dealer',
          'phone': '+971501234567',
          'email': 'dealer@dubisale.com',
        },
        'posts': categoryPosts,
      },
    ];
  }

  // Demo Dropdown Options
  static const Map<String, dynamic> dropdownOptionsResponse = {
    'status': true,
    'msg': 'Options loaded successfully (Demo Mode)',
    'data': [],
  };

  // Demo specific dropdown data
  static const List<Map<String, dynamic>> makes = [
    {
      'id': 1,
      'title_en': 'Audi',
      'title_ar': 'أودي',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 2,
      'title_en': 'BMW',
      'title_ar': 'بي إم دبليو',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 3,
      'title_en': 'Mercedes',
      'title_ar': 'مرسيدس',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 4,
      'title_en': 'Toyota',
      'title_ar': 'تويوتا',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 5,
      'title_en': 'Nissan',
      'title_ar': 'نيسان',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
  ];

  static const List<Map<String, dynamic>> models = [
    {
      'id': 1,
      'title_en': 'A5',
      'title_ar': 'A5',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 2,
      'title_en': 'X5',
      'title_ar': 'X5',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 3,
      'title_en': 'C-Class',
      'title_ar': 'فئة C',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 4,
      'title_en': 'Camry',
      'title_ar': 'كامري',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
  ];

  static const List<Map<String, dynamic>> years = [
    {
      'id': 1,
      'title_en': '2024',
      'title_ar': '2024',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 2,
      'title_en': '2023',
      'title_ar': '2023',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 3,
      'title_en': '2022',
      'title_ar': '2022',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 4,
      'title_en': '2021',
      'title_ar': '2021',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 5,
      'title_en': '2020',
      'title_ar': '2020',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
  ];

  static const List<Map<String, dynamic>> colors = [
    {
      'id': 1,
      'title_en': 'Black',
      'title_ar': 'أسود',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 2,
      'title_en': 'White',
      'title_ar': 'أبيض',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 3,
      'title_en': 'Silver',
      'title_ar': 'فضي',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 4,
      'title_en': 'Blue',
      'title_ar': 'أزرق',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 5,
      'title_en': 'Red',
      'title_ar': 'أحمر',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
  ];

  static const List<Map<String, dynamic>> cities = [
    {
      'id': 1,
      'title_en': 'Dubai',
      'title_ar': 'دبي',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 2,
      'title_en': 'Abu Dhabi',
      'title_ar': 'أبوظبي',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 3,
      'title_en': 'Sharjah',
      'title_ar': 'الشارقة',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 4,
      'title_en': 'Ajman',
      'title_ar': 'عجمان',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 5,
      'title_en': 'Ras Al Khaimah',
      'title_ar': 'رأس الخيمة',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
  ];

  static const List<Map<String, dynamic>> specs = [
    {
      'id': 1,
      'title_en': 'GCC',
      'title_ar': 'خليجي',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 2,
      'title_en': 'American',
      'title_ar': 'أمريكي',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 3,
      'title_en': 'European',
      'title_ar': 'أوروبي',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
    {
      'id': 4,
      'title_en': 'Japanese',
      'title_ar': 'ياباني',
      'created_at': '2024-01-01 10:00:00',
      'updated_at': '2024-01-01 10:00:00',
    },
  ];

  // Demo User Profile
  static const Map<String, dynamic> userProfile = {
    'status': true,
    'msg': 'Profile loaded successfully (Demo Mode)',
    'data': {
      'id': 1,
      'name': 'Demo User',
      'phone': '+971501234567',
      'email': 'demo@dubisale.com',
      'image': 'https://via.placeholder.com/200x200/2C2E83/FFFFFF?text=User',
      'created_at': '2024-01-01',
      'posts_count': 12,
      'favorites_count': 8,
    },
  };

  // Demo Auth Response (Login/Register)
  static const Map<String, dynamic> authSuccessResponse = {
    'status': true,
    'msg': 'Success (Demo Mode)',
    'data': {
      'user': {
        'id': 1,
        'name': 'Demo User',
        'phone': '+971501234567',
        'email': 'demo@dubisale.com',
        'image': 'https://via.placeholder.com/200x200/2C2E83/FFFFFF?text=User',
      },
      'token': 'demo_token_123456789',
      'device_token': 'demo_device_token',
    },
  };

  // Demo Plans Response
  static const Map<String, dynamic> plansResponse = {
    'status': true,
    'msg': 'Plans loaded successfully (Demo Mode)',
    'data': [
      {
        'id': 1,
        'name_en': 'Basic Plan',
        'name_ar': 'خطة أساسية',
        'price': '0',
        'duration': '30',
        'features': ['Post 5 ads', 'Basic support'],
      },
      {
        'id': 2,
        'name_en': 'Premium Plan',
        'name_ar': 'خطة مميزة',
        'price': '299',
        'duration': '30',
        'features': ['Post unlimited ads', 'Featured ads', 'Priority support'],
      },
    ],
  };

  // Helper method to get dropdown data by endpoint
  static Map<String, dynamic> getDropdownData(String endpoint) {
    final Map<String, List<Map<String, dynamic>>> endpointMap = {
      'all/make': makes,
      'all/model': models,
      'all/year': years,
      'all/color': colors,
      'all/interior_color': colors, // Reuse colors
      'all/city': cities,
      'all/spec': specs,
      'all/car_type': [
        {
          'id': 1,
          'title_en': 'Sedan',
          'title_ar': 'سيدان',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        {
          'id': 2,
          'title_en': 'SUV',
          'title_ar': 'دفع رباعي',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        {
          'id': 3,
          'title_en': 'Coupe',
          'title_ar': 'كوبيه',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
      ],
      'all/trans_type': [
        {
          'id': 1,
          'title_en': 'Automatic',
          'title_ar': 'أوتوماتيك',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        {
          'id': 2,
          'title_en': 'Manual',
          'title_ar': 'يدوي',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
      ],
      'all/fuel_type': [
        {
          'id': 1,
          'title_en': 'Petrol',
          'title_ar': 'بنزين',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        {
          'id': 2,
          'title_en': 'Diesel',
          'title_ar': 'ديزل',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        {
          'id': 3,
          'title_en': 'Electric',
          'title_ar': 'كهربائي',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        {
          'id': 4,
          'title_en': 'Hybrid',
          'title_ar': 'هجين',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
      ],
      'all/warranty': [
        {
          'id': 1,
          'title_en': 'Yes',
          'title_ar': 'نعم',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
        {
          'id': 2,
          'title_en': 'No',
          'title_ar': 'لا',
          'created_at': '2024-01-01 10:00:00',
          'updated_at': '2024-01-01 10:00:00',
        },
      ],
    };

    final data = endpointMap[endpoint] ?? [];
    return {
      'status': true,
      'msg': 'Options loaded successfully (Demo Mode)',
      'data': data,
    };
  }
}
