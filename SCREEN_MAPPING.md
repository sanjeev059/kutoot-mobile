# Figma → Kutoot Backend Screen Mapping

## Adapted UI to Current Backend

| Figma Design | Kutoot Backend | Flutter Screen |
|--------------|----------------|----------------|
| Splash | - | `SplashScreen` |
| Login / Sign-up | `/auth/otp/send` | `LoginScreen` |
| OTP Verify | `/auth/otp/verify` | `OtpScreen` |
| Home (banners, categories) | `/hero-settings`, `/marketing-banners`, `/dashboard` | `HomeScreen` |
| Product Listings | → Campaigns | `CampaignsScreen` |
| Product Detail | → Campaign Detail | (TODO) |
| Cart & Checkout | → Coupon redemption + Razorpay | (TODO) |
| Restaurant Listings | → Merchant Locations | (TODO) |
| User Profile | `/profile` | `ProfileScreen` |
| Orders | `/transactions` | (TODO) |
| Refer & Earn | (partial) | (TODO) |
| Subscriptions | `/subscriptions/plans` | (TODO) |
| Notifications | (future) | (TODO) |

## Backend APIs Used

- **Auth:** OTP send/verify, user, logout
- **Campaigns:** List, show, bounty
- **Coupons:** List, show, redeem, calculate, verify-payment
- **Stamps:** List, reserve, reservation flow
- **Subscriptions:** Plans, current, upgrade, verify-payment
- **Transactions:** List, show
- **Profile:** Get, update
- **Merchant Locations:** List (stores)
- **Marketing:** Banners, hero settings
- **QR:** Scan

## Future Extensions (Backend + UI)

- Product catalog
- Restaurant menus
- Booking / reservations
