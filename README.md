# Clippi

AI-powered bookmark manager built with Flutter. The core goal is zero-effort organization — links are automatically titled, categorized, and grouped by AI so users spend less time managing and more time revisiting what they saved.

---

## What Clippi Does

Most bookmark apps stop at saving. Clippi continues from there: AI summarizes titles, suggests subcategories, and groups bookmarks so the collection stays readable without manual work.

For YouTube links, there is a dedicated TikTok-style vertical swipe viewer for quick re-consumption. For X/Twitter links, metadata is fetched through a proxy to ensure clean titles and high-resolution images instead of broken or empty previews.

---

## Features

**Bookmark Management**
- Add bookmarks by URL with automatic metadata fetch (title, description, thumbnail)
- Category-based home screen with custom icons and accent colors
- Subcategory grouping within each category
- Multi-select and batch move to subcategory
- Share sheet integration for saving links directly from other apps

**AI Organization (Gemini)**
- Automatic title summarization — converts raw URLs into short, human-readable titles
- Subcategory suggestion based on category context and existing subcategory patterns
- Smart bookmark analysis — suggests category and subcategory candidates simultaneously from URL, title, and description

**Platform-Specific Handling**
- X/Twitter: routes through `fixupx.com` to extract proper OG tags and high-resolution media
- YouTube: TikTok-style vertical PageView with auto-advance on video end

---

## Tech Stack

- Flutter (Dart)
- Isar (local NoSQL database, reactive streams)
- Google Generative AI SDK (Gemini)
- youtube_player_flutter
- webview_flutter
- flutter_dotenv for environment variable management
- PhosphorIcons for UI icons

---

## Getting Started

**1. Clone the repository**

```bash
git clone https://github.com/saeyoung20cc12-gif/Clippi.git
cd Clippi
```

**2. Set up environment variables**

Copy the example file and fill in your API key:

```bash
cp assets/.env.example assets/.env
```

Open `assets/.env` and replace `YOUR_API_KEY_HERE` with your actual Gemini API key.
You can get a free key at [https://aistudio.google.com](https://aistudio.google.com).

**3. Install dependencies**

```bash
flutter pub get
```

**4. Run the app**

```bash
flutter run
```

> Note: If you modify any Isar entity file, regenerate the schema with:
> ```bash
> dart run build_runner build
> ```

---

## Project Structure

```
lib/
  models/          Isar entity definitions (BookmarkEntity, CategoryEntity)
  services/        IsarService, MetadataService, AiService
  screens/         HomeScreen, CategoryScreen, YoutubeViewerScreen, AddBookmarkSheet
assets/
  .env.example     API key template (copy to .env before running)
```

---

## Planned Features

- iOS Share Extension for faster in-flow saving without opening the app
- Authenticated X/Twitter session persistence for private content
- Scroll and navigation locking within the YouTube viewer
- Improved AI subcategory auto-apply when confidence is high
- Search across bookmarks and categories

---

## Notes

- The `.env` file is excluded from version control. Never commit your actual API key.
- The AI features are entirely optional. The app functions as a standard bookmark manager without a configured API key.
- Isar schema changes require a build_runner rebuild — do not forget this step after modifying entity files.
