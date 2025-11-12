import 'package:flutter/material.dart';
enum NotificationType {
  orderUpdate,
  paymentSuccess,
  paymentFailed,
  shippingUpdate,
  deliveryComplete,
  returnRequest,
  returnApproved,
  returnRejected,
  reviewReceived,
  promotion,
  system,
  sellerMessage,
  sellerApproval,
  sellerExpiry,
  payoutReady,
}

class Notification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  bool get isUnread => !isRead;

  IconData get icon {
    switch (type) {
      case NotificationType.orderUpdate:
        return Icons.shopping_bag;
      case NotificationType.paymentSuccess:
        return Icons.payment;
      case NotificationType.paymentFailed:
        return Icons.error;
      case NotificationType.shippingUpdate:
        return Icons.local_shipping;
      case NotificationType.deliveryComplete:
        return Icons.check_circle;
      case NotificationType.returnRequest:
        return Icons.assignment_return;
      case NotificationType.returnApproved:
        return Icons.check_circle_outline;
      case NotificationType.returnRejected:
        return Icons.cancel;
      case NotificationType.reviewReceived:
        return Icons.star;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.sellerMessage:
        return Icons.message;
      case NotificationType.sellerApproval:
        return Icons.verified;
      case NotificationType.sellerExpiry:
        return Icons.warning;
      case NotificationType.payoutReady:
        return Icons.account_balance_wallet;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.paymentFailed:
      case NotificationType.returnRejected:
      case NotificationType.sellerExpiry:
        return Colors.redAccent;
      case NotificationType.paymentSuccess:
      case NotificationType.deliveryComplete:
      case NotificationType.returnApproved:
      case NotificationType.sellerApproval:
        return Colors.greenAccent;
      case NotificationType.shippingUpdate:
      case NotificationType.orderUpdate:
        return Colors.blueAccent;
      case NotificationType.promotion:
        return Colors.orangeAccent;
      case NotificationType.reviewReceived:
        return Colors.amberAccent;
      case NotificationType.payoutReady:
        return Colors.purpleAccent;
      default:
        return Colors.white70;
    }
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      userId: json['user_id'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      title: json['title'],
      message: json['message'],
      data: json['data'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  Notification markAsRead() {
    return Notification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      data: data,
      isRead: true,
      createdAt: createdAt,
      readAt: DateTime.now(),
    );
  }
}

class NotificationSettings {
  final String userId;
  final bool orderUpdates;
  final bool paymentNotifications;
  final bool shippingUpdates;
  final bool promotionalEmails;
  final bool reviewNotifications;
  final bool sellerMessages;
  final bool systemNotifications;

  NotificationSettings({
    required this.userId,
    this.orderUpdates = true,
    this.paymentNotifications = true,
    this.shippingUpdates = true,
    this.promotionalEmails = false,
    this.reviewNotifications = true,
    this.sellerMessages = true,
    this.systemNotifications = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      userId: json['user_id'],
      orderUpdates: json['order_updates'] ?? true,
      paymentNotifications: json['payment_notifications'] ?? true,
      shippingUpdates: json['shipping_updates'] ?? true,
      promotionalEmails: json['promotional_emails'] ?? false,
      reviewNotifications: json['review_notifications'] ?? true,
      sellerMessages: json['seller_messages'] ?? true,
      systemNotifications: json['system_notifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'order_updates': orderUpdates,
      'payment_notifications': paymentNotifications,
      'shipping_updates': shippingUpdates,
      'promotional_emails': promotionalEmails,
      'review_notifications': reviewNotifications,
      'seller_messages': sellerMessages,
      'system_notifications': systemNotifications,
    };
  }

  NotificationSettings copyWith({
    bool? orderUpdates,
    bool? paymentNotifications,
    bool? shippingUpdates,
    bool? promotionalEmails,
    bool? reviewNotifications,
    bool? sellerMessages,
    bool? systemNotifications,
  }) {
    return NotificationSettings(
      userId: userId,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      paymentNotifications: paymentNotifications ?? this.paymentNotifications,
      shippingUpdates: shippingUpdates ?? this.shippingUpdates,
      promotionalEmails: promotionalEmails ?? this.promotionalEmails,
      reviewNotifications: reviewNotifications ?? this.reviewNotifications,
      sellerMessages: sellerMessages ?? this.sellerMessages,
      systemNotifications: systemNotifications ?? this.systemNotifications,
    );
  }
}