# Esaller - Flutter E-commerce App

A comprehensive Flutter application for an e-commerce platform featuring user authentication, product management, shopping cart, wishlist, returns/refunds, seller management, analytics, and M-Pesa payment integration via Daraja API.

## Features

### User Features
- **Authentication**: Secure signup/login with Supabase Auth, role-based access (user/admin/seller)
- **Product Browsing**: Browse products with search, filtering, and categories
- **Shopping Cart**: Add/remove items, quantity management, cart persistence
- **Wishlist**: Save favorite products, share wishlists
- **Order Management**: Place orders, track status, view order history
- **Returns & Refunds**: Request returns, track refund status
- **Reviews**: Rate and review purchased products
- **Profile Management**: Update personal information, addresses
- **Notifications**: Real-time notifications for orders, payments, etc.

### Seller Features
- **Seller Registration**: Apply to become a seller, admin approval process
- **Product Management**: Add, edit, delete products with image uploads
- **Order Fulfillment**: Manage orders, update shipping status
- **Payout Management**: Request payouts, view payout history
- **Analytics Dashboard**: Sales analytics, customer insights
- **Payment Methods**: Configure payout methods (M-Pesa, bank, etc.)
- **Subscription Management**: Monthly seller subscriptions

### Admin Features
- **User Management**: View/manage all users, roles
- **Seller Approval**: Review and approve seller applications
- **Content Management**: Manage products, categories
- **Order Oversight**: View all orders, intervene if needed
- **Financial Reports**: Platform fees, revenue analytics
- **System Settings**: Configure platform-wide settings

### Payment Features
- **M-Pesa Integration**: STK Push payments via Daraja API
- **Payment Tracking**: Monitor payment status, handle callbacks
- **Refund Processing**: Automated refund workflows
- **Transaction History**: Complete payment audit trail

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **State Management**: Provider pattern
- **Payments**: M-Pesa Daraja API
- **Storage**: Supabase Storage for product images
- **Notifications**: Supabase real-time subscriptions

## Project Structure

```
lib/
├── constants.dart          # App constants and configuration
├── main.dart              # App entry point
├── models/                # Data models
│   ├── user.dart
│   ├── product.dart
│   ├── order.dart
│   ├── wishlist.dart
│   └── ...
├── providers/             # State management
│   ├── auth_provider.dart
│   ├── cart_provider.dart
│   └── ...
├── screens/               # UI screens
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── product_details_screen.dart
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── order_history_screen.dart
│   ├── wishlist_screen.dart
│   ├── returns_screen.dart
│   ├── seller_dashboard_screen.dart
│   ├── admin_dashboard.dart
│   └── ...
├── services/              # Business logic and API calls
│   ├── auth_service.dart
│   ├── product_service.dart
│   ├── order_service.dart
│   ├── payment_service.dart
│   ├── wishlist_service.dart
│   ├── returns_service.dart
│   ├── analytics_service.dart
│   └── ...
├── widgets/               # Reusable UI components
│   ├── glassy_app_bar.dart
│   ├── glassy_container.dart
│   ├── glassy_button.dart
│   ├── loading_overlay.dart
│   ├── error_boundary.dart
│   └── ...
```

## Setup Instructions

### Prerequisites
- Flutter SDK (latest stable version)
- Supabase account
- M-Pesa Daraja API credentials (for payments)

### 1. Flutter Setup
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 2. Supabase Setup
1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Go to SQL Editor and run the contents of `supabase_schema.sql`
   - **Note**: The schema includes automatic migrations to handle updates safely
   - It can be run multiple times without issues
   - Existing data will be preserved during migrations
3. **Email Verification Setup** (Important for production):
   - Go to Authentication > Settings
   - **Disable "Enable email confirmations"** - We handle verification manually in the app to allow admin bypass
   - Configure SMTP settings to avoid spam:
     - Use a reputable email service like SendGrid, Mailgun, or AWS SES
     - Set up SMTP credentials in Authentication > Settings > SMTP Settings
     - This ensures emails don't go to spam folders
   - **Rate Limiting**: To remove email send rate limits (for over_email_send_rate errors):
     - Go to Authentication > Rate Limits
     - Increase or disable the "Email sends per hour" limit
     - Note: This may require a paid Supabase plan for higher limits
4. Get your project URL and anon key from Settings > API
5. Update `lib/constants.dart` with your credentials:
   ```dart
   const String supabaseUrl = 'your-project-url';
   const String supabaseAnonKey = 'your-anon-key';
   ```

### 3. M-Pesa Daraja API Setup
1. Register for M-Pesa Daraja API at [developer.safaricom.co.ke](https://developer.safaricom.co.ke)
2. Get consumer key, consumer secret, shortcode, and passkey
3. Update `lib/constants.dart`:
   ```dart
   const String mpesaConsumerKey = 'your-consumer-key';
   const String mpesaConsumerSecret = 'your-consumer-secret';
   const String mpesaShortcode = 'your-shortcode';
   const String mpesaPasskey = 'your-passkey';
   const String mpesaBaseUrl = 'https://sandbox.safaricom.co.ke'; // or production URL
   ```

### 4. Storage Setup
1. In Supabase Dashboard, go to Storage
2. Create a bucket called `product-images`
3. Set it to public
4. Update storage policies in the schema if needed

## Database Schema

### Core Tables
- `profiles`: User profiles with roles (user/admin/seller)
- `products`: Product catalog with seller information
- `orders`: Order records with status tracking
- `order_items`: Individual items within orders
- `reviews`: Product reviews and ratings
- `wishlist_items`: User wishlists
- `notifications`: Push notifications
- `analytics_events`: User behavior tracking

### Seller Tables
- `sellers`: Seller account information
- `seller_applications`: Seller registration applications
- `seller_extensions`: Subscription extensions
- `payment_methods`: Seller payout methods
- `payout_requests`: Payout requests
- `seller_payout_methods`: Payout method configurations

### Payment Tables
- `payment_initiations`: M-Pesa payment requests
- `transactions`: Payment records
- `refunds`: Refund tracking
- `platform_fees`: Platform revenue tracking

### Advanced Features
- `return_requests`: Return/refund requests
- `order_tracking`: Order status updates
- `order_shipments`: Shipping information
- `stock_changes`: Inventory tracking
- `review_reports`: Review moderation
- `analytics_data`: Seller analytics
- `notification_settings`: User preferences

## API Integration

### M-Pesa Daraja API
- **STK Push**: Initiate payments from mobile
- **C2B**: Receive payments (for production)
- **B2C**: Send payouts to sellers
- **Transaction Status**: Query payment status

### Supabase Features Used
- **Authentication**: User signup/login, password reset
- **Database**: PostgreSQL with RLS policies
- **Storage**: File uploads for product images
- **Real-time**: Live notifications and updates
- **Edge Functions**: Serverless functions for payments

## Security Features

- **Row Level Security (RLS)**: Database-level access control
- **JWT Authentication**: Secure API access
- **Input Validation**: Client and server-side validation
- **HTTPS Only**: Secure communication
- **Role-based Access**: Different permissions for users/sellers/admins

## Deployment

### Mobile App
```bash
# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release
```

### Backend (Supabase)
- Database schema is automatically deployed via SQL
- Edge Functions can be deployed via Supabase CLI
- Storage buckets are configured in schema

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Payment Testing
- Use M-Pesa sandbox environment
- Test STK Push flow
- Verify callback handling

## Troubleshooting

### Database Issues
- **Schema Updates**: The `supabase_schema.sql` includes automatic migrations. Re-run it in Supabase SQL Editor if you encounter table-related errors.
- **Connection Issues**: Verify your Supabase URL and keys in `lib/constants.dart` are correct.
- **RLS Policies**: If data isn't loading, check that Row Level Security policies are properly configured.
- **Migration Errors**: The schema is designed to be idempotent. If migrations fail, check Supabase logs for details.

### Build Issues
- **Dependencies**: Run `flutter pub get` to ensure all packages are installed.
- **Platform Setup**: For Android/iOS builds, ensure platform-specific configurations are complete.
- **Environment Variables**: Double-check all API keys and URLs are properly set.

### Payment Issues
- **M-Pesa Sandbox**: Use sandbox credentials for testing, production credentials for live app.
- **Callback URLs**: Ensure your callback URLs are correctly configured in Daraja dashboard.
- **Network Issues**: M-Pesa APIs may have timeouts; implement retry logic in your payment service.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email support@esaller.com or join our Discord community.

## Roadmap

- [ ] Multi-language support
- [ ] Advanced analytics dashboard
- [ ] Mobile wallet integrations
- [ ] AI-powered product recommendations
- [ ] Live chat support
- [ ] Social commerce features
