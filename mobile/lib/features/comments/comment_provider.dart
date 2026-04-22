import 'package:flutter/foundation.dart';
import 'comment_service.dart';
import 'models/comment_model.dart';
import '../../core/services/socket_service.dart';

class CommentProvider with ChangeNotifier {
  final CommentService _service = CommentService();
  final SocketService _socketService = SocketService();

  List<CommentModel> _comments = [];
  bool _isLoading = false;

  List<CommentModel> get comments => _comments;
  bool get isLoading => _isLoading;

  void listenToComments(int incidentId) {
     try {
       _socketService.socket.on('comment_added', (data) {
          if (data['incidentId'] == incidentId) {
             final newComment = CommentModel.fromJson(data['comment']);
             if (!_comments.any((c) => c.commentId == newComment.commentId)) {
                _comments.add(newComment);
                notifyListeners();
             }
          }
       });
     } catch (e) {
       debugPrint('Socket error in listenToComments: $e');
     }
  }

  void stopListening() {
    try {
      _socketService.socket.off('comment_added');
    } catch (e) {
      debugPrint('Socket error in stopListening: $e');
    }
  }

  Future<void> loadComments(int incidentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _comments = await _service.getComments(incidentId);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addComment(int incidentId, String content) async {
    try {
      final comment = await _service.createComment(incidentId, content);
      if (!_comments.any((c) => c.commentId == comment.commentId)) {
         _comments.add(comment);
         notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
}
