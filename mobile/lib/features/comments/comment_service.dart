import '../../core/services/api_service.dart';
import 'models/comment_model.dart';

class CommentService {
  final ApiService _api = ApiService();

  Future<List<CommentModel>> getComments(int incidentId) async {
    final response = await _api.get('/comments/$incidentId');
    return (response.data as List)
        .map((json) => CommentModel.fromJson(json))
        .toList();
  }

  Future<CommentModel> createComment(int incidentId, String content) async {
    final response = await _api.post(
      '/comments/$incidentId',
      body: {'content': content},
    );
    return CommentModel.fromJson(response.data);
  }
}
