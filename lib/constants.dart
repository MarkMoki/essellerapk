// Supabase configuration
const String supabaseUrl = 'https://oqonmjuxpkqrpfnhcmfs.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9xb25tanV4cGtxcnBmbmhjbWZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NzgwNTcsImV4cCI6MjA3ODU1NDA1N30.sA2ftZdpAqClYeJh0xWfanpxSk9DABZXdjR3m0FmvOA';

// Daraja API configuration
const String darajaConsumerKey = 'YOUR_CONSUMER_KEY';
const String darajaConsumerSecret = 'YOUR_CONSUMER_SECRET';
const String darajaShortcode = 'YOUR_SHORTCODE'; // e.g., '174379'
const String darajaPasskey = 'YOUR_PASSKEY';
const String darajaBaseUrl = 'https://sandbox.safaricom.co.ke'; // or production

// Utility function for user-friendly error messages
String getUserFriendlyErrorMessage(dynamic error) {
  if (error == null) return 'An unexpected error occurred. Please try again.';

  String errorStr = error.toString().toLowerCase();

  if (errorStr.contains('network') || errorStr.contains('connection') || errorStr.contains('socket')) {
    return 'Network error. Please check your internet connection and try again.';
  }

  if (errorStr.contains('timeout')) {
    return 'Request timed out. Please try again.';
  }

  if (errorStr.contains('unauthorized') || errorStr.contains('permission') || errorStr.contains('forbidden')) {
    return 'You do not have permission to perform this action.';
  }

  if (errorStr.contains('not found') || errorStr.contains('404')) {
    return 'The requested item was not found.';
  }

  if (errorStr.contains('server') || errorStr.contains('internal')) {
    return 'Server error. Please try again later.';
  }

  // Default user-friendly message
  return 'Something went wrong. Please try again later.';
}
