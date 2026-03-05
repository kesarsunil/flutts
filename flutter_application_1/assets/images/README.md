## Smart Park Logo Setup

### How to Add the Logo Image

1. Save the Smart Park logo image (the image with the location pin and car icon with "SMART PARK" text) to:

   ```
   assets/images/smart_park_logo.png
   ```

2. The image should be in PNG format for best quality with transparency support.

### Current Configuration

The app has been configured to display the Smart Park logo as a background on:

- **Login Page** (Sign In view)
- **Sign Up Page**
- **User Page** (Main dashboard)

The logo appears with:

- Semi-transparent overlay (30% opacity on login pages, 15% on user page)
- Gradient overlay to maintain readability of foreground content
- Cover fit to fill the entire background

### Running the App

After placing the image file, run:

```bash
flutter pub get
flutter run
```

The logo will automatically appear as the background on these pages.
