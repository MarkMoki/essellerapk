import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Notification>> getNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => Notification.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<List<Notification>> getUnreadNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .order('created_at', ascending: false);

      return response.map((json) => Notification.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch unread notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'data': data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  Future<NotificationSettings> getNotificationSettings(String userId) async {
    try {
      final response = await _supabase
          .from('notification_settings')
          .select()
          .eq('user_id', userId)
          .single();

      return NotificationSettings.fromJson(response);
    } catch (e) {
      // If no settings exist, return default settings
      return NotificationSettings(userId: userId);
    }
  }

  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    try {
      await _supabase.from('notification_settings').upsert(settings.toJson());
    } catch (e) {
      throw Exception('Failed to update notification settings: $e');
    }
  }

  // Send push notification via FCM (if implemented)
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // This would integrate with Firebase Cloud Messaging or similar service
    // For now, just create a database notification
    await createNotification(
      userId: userId,
      type: NotificationType.system,
      title: title,
      message: body,
      data: data,
    );
  }
}