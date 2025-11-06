# Esaller - Flutter E-commerce App

A Flutter application for an e-commerce platform with user authentication, product management, shopping cart, and M-Pesa payment integration via Daraja API.

## Features

- **Authentication**: User signup/login with Supabase Auth, role-based access (user/admin)
- **Product Management**: Admin can add, edit, delete products with images
- **Shopping**: Users can browse products, add to cart, checkout
- **Payments**: M-Pesa STK Push integration for payments
- **Order Management**: Order creation and status tracking

## Setup

1. **Flutter Setup**:
   - Ensure Flutter is installed
   - Run `flutter pub get`

2. **Supabase Setup**:
   - Create a Supabase project
   - Run the SQL in `supabase_schema.sql` in the Supabase SQL editor
   - Get your project URL and anon key
   - Update `lib/constants.dart` with your Supabase credentials

3. **Daraja API Setup**:
   - Register for M-Pesa Daraja API
   - Get consumer key, secret, shortcode, passkey
   - Update `lib/constants.dart` with Daraja credentials
   - For production, update the base URL

4. **Run the App**:
   - `flutter run`

## Database Schema

- `profiles`: User profiles with roles
- `products`: Product catalog
- `orders`: User orders with items and status

## Architecture

- **Frontend**: Flutter with Provider for state management
- **Backend**: Supabase (Auth, Database, Storage)
- **Payments**: Daraja M-Pesa API

## Notes

- Payment callbacks: In a real app, use Supabase Edge Functions or a server to handle M-Pesa callbacks and update order status.
- For testing, use Daraja sandbox environment.
- Replace placeholder URLs and keys in `constants.dart`.
