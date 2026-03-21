# Kutoot App — Figma Design Specification

Use this document to recreate the Kutoot mobile app in Figma. Copy sections into Figma AI, or follow manually.

---

## 1. DESIGN SYSTEM

### Colors (Hex)
| Name | Hex | Usage |
|------|-----|-------|
| Primary (Kutoot Orange) | `#FF6B35` | Buttons, accents, selected states |
| Primary Dark | `#E55A2B` | Gradients, hover |
| Primary Light (Splash) | `#FF8A65` | Splash gradient top |
| Background | `#F5F5F5` | App background |
| Surface | `#FFFFFF` | Cards, inputs, app bar |
| Text Primary | `#333333` | Headlines, body |
| Text Secondary | `#666666` | Subtitle, hints |
| Border | `#E0E0E0` | Input borders |
| Success/Positive | `#4CAF50` (green) | Credit amounts |
| Error/Logout | `#F44336` (red) | Delete, logout |
| Star Rating | `#FFA000` (amber) | Ratings |

### Typography
- **Headlines**: Bold, 24–32px, color #333333
- **Body**: Regular/Medium, 14–16px, color #333333
- **Subtitle/Hints**: 12–14px, color #666666
- **Button**: 16px, font-weight 600

### Spacing
- Screen padding: 16–24px
- Card padding: 16–24px
- Section gaps: 12–24px
- Icon-text gap: 4–8px

### Border Radius
- Small (chips, icons): 8–12px
- Medium (cards, inputs): 12–16px
- Large (buttons, banners): 20–26px
- Circle (avatars): 50%

### Shadows
- Card: `0 2px 12px rgba(0,0,0,0.06)`
- Elevated: `0 4px 16px rgba(0,0,0,0.08)`
- Primary glow: `0 8px 24px rgba(255,107,53,0.3)`

---

## 2. PROMPTS FOR FIGMA AI (copy-paste)

**Design System prompt:**
```
Create a design system for a loyalty/rewards app called Kutoot.
Colors: Primary #FF6B35, Background #F5F5F5, Surface white, Text #333333.
Rounded corners (12–26px), Material-style shadows. Modern, clean, mobile-first.
```

**App Icon prompt:**
```
App icon: white rounded square (20px radius) with orange shopping bag icon inside.
Brand name: "Kutoot" in bold white, tagline "SHOP • SAVE • WIN" in smaller white.
```

---

## 3. SCREENS (Wireframe + Specs)

### 3.1 Splash Screen
- **Background**: Vertical gradient `#FF8A65` → `#FF6B35` → `#E55A2B`
- **Logo**: 100×100 white rounded rectangle (20px radius), shopping bag icon (#FF6B35) 56px
- **Text**: "Kutoot" 32px bold white
- **Tagline**: "SHOP • SAVE • WIN" 14px, letter-spacing 2, white 90%
- **Loading**: Circular progress indicator, white, 28×28

---

### 3.2 Login Screen
- **Layout**: Centered, padding 24px
- **Title**: "Log in or Sign up" — headline, bold
- **Subtitle**: "Enter your mobile number" — body, gray
- **Input**: Row with country code (+91) dropdown, divider, text field "Phone number or email"
- **Input box**: White, border #E0E0E0, radius 12px, padding 16px
- **Button**: Full-width, 52px height, orange, "Next", radius 26px
- **Footer**: "By continuing, you agree to our Terms of Service and Privacy Policy" 12px gray, centered

---

### 3.3 OTP Screen
- **Header**: Back arrow
- **Icon**: 56×56 orange rounded square, shopping bag icon white
- **Title**: "Verify your phone number"
- **Subtitle**: "Enter the 6-digit code sent to [identifier]"
- **OTP**: 6 separate input boxes, 48×48 each, radius 12px, center-aligned digits
- **Resend**: "Resend OTP" or "Resend OTP in 60s"
- **Button**: Full-width orange "Verify" with arrow icon

---

### 3.4 Home / Explore (Main Tab)
- **Search bar**: Rounded 14px, gray fill, search icon, "Search merchants, schemes, or deals"
- **Category chips**: Horizontal scroll, FilterChip style — Food, Fashion, Coffee, Retail, Beauty, More (icons + labels)
- **Quick actions**: 4 icons in row — Scan, Rewards, Stores, Deals — each: icon in orange-tinted circle, label below
- **Banner carousel**: 320×170 cards, radius 20px, horizontal scroll
- **Fallback banner** (no data): 180px height, gradient orange, decorative icons, "Featured Campaigns", "Pull to refresh"
- **Section**: "Top Deals Near You" + "See all" link
- **Deal cards**: 170×180, white, image 170×110 top, title below; radius 20px
- **Stamp Program card**: White with orange tint, loyalty icon, progress bar, "X/Y stamps earned"
- **Section**: "Nearby Merchants"
- **Merchant cards**: Row — 72×72 store image, name, rating (star + number), distance, stamp text, chevron
- **FAB**: Orange circular, QR scanner icon, bottom-right

---

### 3.5 Bottom Navigation (4 tabs)
- **Items**: Home (explore), Rewards, Wallet, Profile
- **Icons**: explore_rounded, card_giftcard_rounded, account_balance_wallet_rounded, person_rounded
- **Selected**: Orange #FF6B35
- **Unselected**: Gray #666666
- **Bar**: White, top shadow

---

### 3.6 Rewards Screen
- **App bar**: "Rewards"
- **Cards** (3): White, radius 16px, shadow
  - Leading: 48×48 orange-tinted circle with icon
  - Title + subtitle
  - Chevron right
- Cards: "Redeem Rewards", "My Rewards", "Rewards Progress"

---

### 3.7 Wallet Screen
- **App bar**: "Wallet"
- **Balance card**: Full width, gradient orange, radius 20px, shadow
  - "Balance" 14px white 70%
  - Amount "$1,240.50" 32px bold white
  - Two buttons: "Top Up", "Withdraw" — outlined white
- **Section**: "Recent Transactions" + "See all"
- **Transaction rows**: White card, 48×48 orange circle icon, name + date, amount (green if +, dark if -)

---

### 3.8 Profile Screen
- **App bar**: "Profile", notification icon right
- **Avatar**: 96×96 circular, orange tint if no photo, initial letter
- **Name**: Title large bold
- **Email**: Gray
- **Stats**: Row — "24" Life Rewards, "5" Total Coupons (value orange, label gray)
- **Menu tiles**: White cards, icon (orange) + title + chevron
  - Edit Profile, Subscription, e-Gift Balance, Transaction History, Saved Items, Payment Methods, Notifications, Help & Support, My Coupons, My Stamps, Stamp History, Refer & Earn, Terms of Service, Settings
- **Logout**: Last tile, logout icon

---

### 3.9 Store Profile
- **Header**: Collapsible 180px image/gradient, store photo or orange gradient
- **Content**: Store name 24px bold, category, star rating
- **Stamp loyalty box**: Black #333, "STAMP LOYALTY", stamp rule text
- **Deals & Offers**: White cards, offer title + subtitle, "Use Offer" button
- **Bank Offers**: Horizontal scroll, 120×80 cards

---

### 3.10 Campaigns Screen
- **App bar**: "Campaigns"
- **List**: White cards, 56×56 leading image (or orange icon), title, subtitle, chevron

---

### 3.11 Onboarding (4 slides)
- **Layout**: Skip button top-right (slides 2–4)
- **Each slide**: 120×120 orange-tinted rounded square with icon, title 24px, subtitle 16px
- **Page indicators**: Dots, active 24×8, inactive 8×8
- **Button**: Full-width orange with arrow
- **Slide 3 extra**: "Already have an account? Sign In" link

---

### 3.12 Settings Screen
- **Sections**: Notifications, Security, Preferences, About, Account
- **Section titles**: 14px gray
- **Tiles**: White cards with Switch or chevron
- **Logout**: Red outlined button

---

## 4. REUSABLE COMPONENTS

| Component | Specs |
|-----------|-------|
| Primary Button | Orange fill, 52px height, radius 26px, white text |
| Outlined Button | White stroke, orange or white text |
| Input | White fill, border #E0E0E0, radius 12px, padding 16px |
| Card | White, radius 12–20px, shadow 0 2px 12px rgba(0,0,0,0.06) |
| List Tile | Icon 48×48, title + subtitle, chevron |
| Filter Chip | Background #F5F5F5, selected orange 15%, avatar 24×24 |
| Avatar | 48–96px, circle, orange tint fallback |
| App Bar | White, no elevation, title bold, icons |

---

## 5. FIGMA FRAME SETTINGS

- **Device**: iPhone 14 / 390×844 (or Android 360×800)
- **Safe area**: Top 44, bottom 34
- **Grid**: 8px base grid

---

## 6. QUICK AI PROMPT (all-in-one)

```
Design a mobile loyalty app "Kutoot" — orange (#FF6B35) brand, white cards, gray text.
Screens: Splash (orange gradient + logo), Login (phone input + Next), OTP (6-digit boxes),
Home (search, category chips, banner carousel, deal cards, stamp progress, merchant list, QR FAB),
Rewards (3 cards), Wallet (balance card + transactions), Profile (avatar, stats, menu),
Store profile (hero image, stamp box, deals). Bottom nav: Home, Rewards, Wallet, Profile.
Style: Material 3, rounded 12–26px, subtle shadows.
```

---

*Generated from Kutoot Flutter app — use with Figma, Figma AI, or share with a designer.*
