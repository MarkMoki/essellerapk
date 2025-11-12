import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      // If profile doesn't exist, return null
      return null;
    }
  }

  // Create or update user profile
  Future<UserProfile> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      final updateData = {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('user_profiles')
          .upsert({
            'id': userId,
            ...updateData,
          })
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get user addresses
  Future<List<Address>> getUserAddresses(String userId) async {
    try {
      final response = await _supabase
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return response.map((json) => Address.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load addresses: $e');
    }
  }

  // Add new address
  Future<Address> addAddress(String userId, Map<String, dynamic> addressData) async {
    try {
      // If this is the default address, unset other defaults
      if (addressData['is_default'] == true) {
        await _supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId);
      }

      final response = await _supabase
          .from('addresses')
          .insert({
            'user_id': userId,
            ...addressData,
          })
          .select()
          .single();

      return Address.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  // Update address
  Future<Address> updateAddress(String addressId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from('addresses')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', addressId)
          .select()
          .single();

      return Address.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  // Delete address
  Future<void> deleteAddress(String addressId) async {
    try {
      await _supabase
          .from('addresses')
          .delete()
          .eq('id', addressId);
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  // Set default address
  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      // First, unset all defaults for this user
      await _supabase
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', userId);

      // Then set the new default
      await _supabase
          .from('addresses')
          .update({'is_default': true})
          .eq('id', addressId);
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }

  // Get notification settings
  Future<Map<String, dynamic>> getNotificationSettings(String userId) async {
    try {
      final response = await _supabase
          .from('notification_settings')
          .select()
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      // Return default settings if not found
      return {
        'order_updates': true,
        'payment_notifications': true,
        'shipping_updates': true,
        'promotional_emails': false,
        'review_notifications': true,
        'seller_messages': true,
        'system_notifications': true,
      };
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await _supabase
          .from('notification_settings')
          .upsert({
            'user_id': userId,
            ...settings,
          });
    } catch (e) {
      throw Exception('Failed to update notification settings: $e');
    }
  }
}