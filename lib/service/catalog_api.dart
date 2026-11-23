import 'dart:convert';

import 'package:http/http.dart' as http;

enum CatalogSort {
  nearestExpiry('nearest_expiry', 'Nearest expiry'),
  priceLowHigh('price_low_high', 'Price: low to high'),
  priceHighLow('price_high_low', 'Price: high to low'),
  nearest('nearest', 'Nearest to me'),
  biggestDiscount('biggest_discount', 'Biggest discount'),
  newest('newest', 'Newest');

  final String apiValue;
  final String label;
  const CatalogSort(this.apiValue, this.label);
  bool get needsLocation => this == CatalogSort.nearest;
}

class CatalogFilters {
  Set<String> categories;
  Set<String> tags; 
  String? listingType; 
  double? minPrice;
  double? maxPrice;
  int? minDiscount;
  int? expiringWithinHours;
  double? maxDistanceKm;
  bool includeSoldOut;

  CatalogFilters({
    Set<String>? categories,
    Set<String>? tags,
    this.listingType,
    this.minPrice,
    this.maxPrice,
    this.minDiscount,
    this.expiringWithinHours,
    this.maxDistanceKm,
    this.includeSoldOut = false,
  })  : categories = categories ?? <String>{},
        tags = tags ?? <String>{};

  CatalogFilters copy() => CatalogFilters(
        categories: {...categories},
        tags: {...tags},
        listingType: listingType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minDiscount: minDiscount,
        expiringWithinHours: expiringWithinHours,
        maxDistanceKm: maxDistanceKm,
        includeSoldOut: includeSoldOut,
      );

  int get activeCount =>
      (categories.isNotEmpty ? 1 : 0) +
      (tags.isNotEmpty ? 1 : 0) +
      (listingType != null ? 1 : 0) +
      (minPrice != null || maxPrice != null ? 1 : 0) +
      (minDiscount != null ? 1 : 0) +
      (expiringWithinHours != null ? 1 : 0) +
      (maxDistanceKm != null ? 1 : 0) +
      (includeSoldOut ? 1 : 0);

  void clear() {
    categories.clear();
    tags.clear();
    listingType = null;
    minPrice = null;
    maxPrice = null;
    minDiscount = null;
    expiringWithinHours = null;
    maxDistanceKm = null;
    includeSoldOut = false;
  }

  Map<String, String> toQueryParameters() => {
        if (categories.isNotEmpty) 'category': categories.join(','),
        if (tags.isNotEmpty) 'tags': tags.join(','),
        if (listingType != null) 'listing_type': listingType!,
        if (minPrice != null) 'min_price': minPrice.toString(),
        if (maxPrice != null) 'max_price': maxPrice.toString(),
        if (minDiscount != null) 'min_discount': minDiscount.toString(),
        if (expiringWithinHours != null)
          'expiring_within_hours': expiringWithinHours.toString(),
        if (maxDistanceKm != null) 'max_distance_km': maxDistanceKm.toString(),
        if (includeSoldOut) 'include_sold_out': 'true',
      };
}

class CatalogBusiness {
  final int id;
  final String name;
  final String? address;
  final double lat;
  final double lng;

  const CatalogBusiness({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory CatalogBusiness.fromJson(Map<String, dynamic> j) => CatalogBusiness(
        id: j['id'] as int,
        name: j['name'] as String,
        address: j['address'] as String?,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
      );
}

class CatalogItem {
  final int id;
  final String title;
  final String description;
  final String category;
  final String listingType; 
  final double price; 
  final double originalPrice; 
  final int discountPercent;
  final int quantityLeft;
  final DateTime expiryAt;
  final int expiresInMinutes; 
  final DateTime? pickupStart;
  final DateTime? pickupEnd;
  final List<String> tags;
  final String? imageUrl;
  final double? distanceKm;
  final CatalogBusiness business;

  const CatalogItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.listingType,
    required this.price,
    required this.originalPrice,
    required this.discountPercent,
    required this.quantityLeft,
    required this.expiryAt,
    required this.expiresInMinutes,
    required this.pickupStart,
    required this.pickupEnd,
    required this.tags,
    required this.imageUrl,
    required this.distanceKm,
    required this.business,
  });

  bool get isDonation => listingType == 'donation';
  bool get isSoldOut => quantityLeft <= 0;

  String get priceLabel => isDonation || price == 0
      ? 'Free'
      : 'RM ${price.toStringAsFixed(2)}';

  String get expiryLabel {
    final left = expiryAt.difference(DateTime.now());
    if (left.isNegative) return 'Expired';
    if (left.inMinutes < 60) return '${left.inMinutes} min left';
    if (left.inHours < 24) return '${left.inHours} h left';
    return '${left.inDays} d left';
  }

  factory CatalogItem.fromJson(Map<String, dynamic> j) => CatalogItem(
        id: j['id'] as int,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        category: j['category'] as String,
        listingType: j['listing_type'] as String,
        price: (j['price'] as num).toDouble(),
        originalPrice: (j['original_price'] as num).toDouble(),
        discountPercent: j['discount_percent'] as int,
        quantityLeft: j['quantity_left'] as int,
        expiryAt: DateTime.parse(j['expiry_at'] as String).toLocal(),
        expiresInMinutes: j['expires_in_minutes'] as int,
        pickupStart: j['pickup_start'] == null
            ? null
            : DateTime.parse(j['pickup_start'] as String).toLocal(),
        pickupEnd: j['pickup_end'] == null
            ? null
            : DateTime.parse(j['pickup_end'] as String).toLocal(),
        tags: (j['tags'] as List).cast<String>(),
        imageUrl: j['image_url'] as String?,
        distanceKm: (j['distance_km'] as num?)?.toDouble(),
        business:
            CatalogBusiness.fromJson(j['business'] as Map<String, dynamic>),
      );
}

class CatalogPage {
  final List<CatalogItem> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool hasNext;

  const CatalogPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    required this.hasNext,
  });

  factory CatalogPage.fromJson(Map<String, dynamic> j) => CatalogPage(
        items: (j['items'] as List)
            .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: j['page'] as int,
        pageSize: j['page_size'] as int,
        total: j['total'] as int,
        totalPages: j['total_pages'] as int,
        hasNext: j['has_next'] as bool,
      );
}

class CatalogFacet {
  final String name;
  final int count;

  const CatalogFacet({required this.name, required this.count});

  factory CatalogFacet.fromJson(Map<String, dynamic> j) =>
      CatalogFacet(name: j['name'] as String, count: j['count'] as int);
}

class CatalogFacets {
  final List<CatalogFacet> categories;
  final List<CatalogFacet> tags;
  final double? minPrice;
  final double? maxPrice;
  final int maxDiscountPercent;

  const CatalogFacets({
    required this.categories,
    required this.tags,
    required this.minPrice,
    required this.maxPrice,
    required this.maxDiscountPercent,
  });

  factory CatalogFacets.fromJson(Map<String, dynamic> j) => CatalogFacets(
        categories: (j['categories'] as List)
            .map((e) => CatalogFacet.fromJson(e as Map<String, dynamic>))
            .toList(),
        tags: (j['tags'] as List)
            .map((e) => CatalogFacet.fromJson(e as Map<String, dynamic>))
            .toList(),
        minPrice: (j['min_price'] as num?)?.toDouble(),
        maxPrice: (j['max_price'] as num?)?.toDouble(),
        maxDiscountPercent: (j['max_discount_percent'] as num?)?.toInt() ?? 0,
      );
}

class CatalogApiException implements Exception {
  final int? statusCode;
  final String message;
  final List<String> details;

  const CatalogApiException(this.message,
      {this.statusCode, this.details = const []});

  @override
  String toString() => details.isEmpty ? message : '$message: ${details.join('; ')}';
}

class CatalogService {
  final String baseUrl;
  final http.Client _client;

  CatalogService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Future<CatalogPage> search({
    String query = '',
    CatalogFilters? filters,
    CatalogSort sort = CatalogSort.nearestExpiry,
    int page = 1,
    int pageSize = 20,
    double? lat,
    double? lng,
  }) async {
    final hasLocation = lat != null && lng != null;
    final params = <String, String>{
      if (query.trim().isNotEmpty) 'q': query.trim(),
      ...?filters?.toQueryParameters(),
      'sort': sort.apiValue,
      'page': '$page',
      'page_size': '$pageSize',
      if (hasLocation) 'lat': '$lat',
      if (hasLocation) 'lng': '$lng',
    };

    if (!hasLocation) {
      if (params['sort'] == CatalogSort.nearest.apiValue) {
        params['sort'] = CatalogSort.nearestExpiry.apiValue;
      }
      params.remove('max_distance_km');
    }

    final uri = Uri.parse('$baseUrl/api/catalog').replace(queryParameters: params);
    final http.Response res;
    try {
      res = await _client.get(uri).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw CatalogApiException('Could not reach the server');
    }

    if (res.statusCode == 200) {
      return CatalogPage.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    List<String> details = const [];
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      details = (body['details'] as List?)?.cast<String>() ?? const [];
    } catch (_) {}
    throw CatalogApiException('Catalog request failed',
        statusCode: res.statusCode, details: details);
  }

  Future<CatalogFacets> facets() async {
    final uri = Uri.parse('$baseUrl/api/catalog/facets');
    final http.Response res;
    try {
      res = await _client.get(uri).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw CatalogApiException('Could not reach the server');
    }
    if (res.statusCode != 200) {
      throw CatalogApiException('Could not load filter options',
          statusCode: res.statusCode);
    }
    return CatalogFacets.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void dispose() => _client.close();
}
