import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:leami_desktop/models/review.dart';
import 'package:leami_desktop/models/review_soft_delete.dart';
import 'package:leami_desktop/providers/base_provider.dart';

class ReviewProvider extends BaseProvider<Review> {
  ReviewProvider() : super("Review");

  @override
  Review fromJson(dynamic json) {
    return Review.fromJson(json as Map<String, dynamic>);
  }

  Future<Review> softDelete({
    required int reviewId,
    required String deletionReason,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint/softDelete');

    final dto = ReviewSoftDeleteRequest(
      reviewId: reviewId,
      deletionReason: deletionReason,
    );
    final body = jsonEncode(dto.toJson());
    final headers = getHeaders();

    final response = await http.put(uri, headers: headers, body: body);
    ensureValidResponseOrThrow(response);

    final data = jsonDecode(response.body);
    return fromJson(data);
  }
}
