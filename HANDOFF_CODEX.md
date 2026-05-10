# Clippi Project Handoff Document (for Codex)

This document provides a detailed technical overview of the current state of "Clippi," a snackable bookmark manager application.

## 1. Project Purpose
- **Main Goal**: A premium AI-powered bookmark manager that aims for **"Zero-Effort Organization."**
- **Core Vision**: 
    - **Intelligent Organization (Primary)**: Using AI (Gemini) for automatic title summarization, sub-categorization, and contextual grouping so users never have to manually organize links.
    - **Premium UI/UX**: minimalist aesthetics with smooth animations and a focus on high-end metadata presentation.
    - **Fluid Consumption (Secondary)**: "Snackable" viewing experiences (e.g., vertical scroll for YouTube) to browse saved content efficiently.

## 2. Currently Implemented (Completed)
- **Database (Isar)**: 
    - `IsarService` implements full CRUD for `CategoryEntity` and `BookmarkEntity`.
    - Reactive UI using Isar's `.watch()` and `.watchLazy()`.
- **UI Architecture**:
    - `HomeScreen`: Displays category cards with custom icons and accent colors.
    - `CategoryScreen`: Lists bookmarks grouped by `subCategory`. 
    - **Sub-Category Management**: Supports inline manual creation, automatic grouping, and "Move to Sub-Category" batch action via multi-selection.
- **Metadata Fetching (`MetadataService`)**: 
    - Custom handling for `x.com` and `twitter.com` using `fixupx.com` as a proxy to extract clean OG tags (titles as tweet content, high-res user/media images).
- **Core Viewer (`YoutubeViewerScreen`)**:
    - TikTok-style vertical `PageView`.
    - Auto-advance to the next item when a video ends.
    - Specific handling for YouTube Shorts/Videos using `youtube_player_flutter`.

## 3. In-Progress (Partial Implementation)
- **AI-driven Features (`AiService`)**:
    - **Gemini 1.5 Flash Integration**: Connected to `google_generative_ai`.
    - `generateSummaryTitle`: Summarizes raw URLs into 10-character human-readable titles. Used during bookmark addition.
    - `suggestSubCategory`: Recommends a sub-category (e.g., "Tops", "Recipes") based on the current category context.
- **Sub-Category UX**: 
    - Manual "Add Sub-Category" dialog is implemented in `CategoryScreen`.
    - "Move to Sub-Category" logic is fully functional via `IsarService.instance.updateBookmarksSubCategory`.

## 4. Pending / Future Roadmap
- **YouTube Viewer Optimization**:
    - Refining the `YoutubeViewerScreen` to handle various aspect ratios and metadata display.
- **Persistent SNS Sessions (X/Twitter focus)**:
    - Support for cookie persistence to allow viewing private or authenticated content (specifically for X/Twitter profile views/media).
- **UX Polish**:
    - Navigation locks and scroll-blocking within the video viewer to prevent accidental exits.
- **AI Accuracy**:
    - Refining prompts for better categorization and summary quality.

## 5. Key Modified Files & Roles
- [isar_service.dart](file:///Users/mac/Documents/Clippi/clippi/lib/services/isar_service.dart): Singleton DB service. Handles transactions (`writeTxn`) and watchers.
- [metadata_service.dart](file:///Users/mac/Documents/Clippi/clippi/lib/services/metadata_service.dart): URL parser. Note the `_fetchTwitter` logic using `fixupx.com`.
- [category_screen.dart](file:///Users/mac/Documents/Clippi/clippi/lib/screens/category_screen.dart): Complex list UI. Handles state for "Delete Mode" and "Sub-Category" grouping logic (`_groupBySubCategory`).
- [youtube_viewer_screen.dart](file:///Users/mac/Documents/Clippi/clippi/lib/screens/youtube_viewer_screen.dart): Vertical PageView player logic.
- [add_bookmark_sheet.dart](file:///Users/mac/Documents/Clippi/clippi/lib/screens/add_bookmark_sheet.dart): Bookmark creation flow. Triggers `MetadataService` and `AiService` automatically when a URL is pasted.
- [ai_service.dart](file:///Users/mac/Documents/Clippi/clippi/lib/services/ai_service.dart): Gemini API wrapper for summaries and categorization.

## 6. Data & State Architecture
- **Database**: Isar (NoSQL).
- **Models**:
    - `BookmarkEntity`: Contains `url`, `title`, `thumbnailUrl`, `memo`, `categoryId`, `subCategory`, `createdAt`.
    - `CategoryEntity`: Contains `label`, `iconName`, `accentColorValue`, `sortOrder`.
- **State Management**: Simple `StatefulWidget` combined with Isar Streams. No heavy state management (Provider/Bloc) used yet, keeping it lightweight.
- **Flow**: `HomeScreen` (Watch Categories) -> `CategoryScreen` (Watch Bookmarks) -> `AddBookmarkSheet` (Write Txn) -> Stream automatically updates UI.

## 7. Precautions & Rules
- **Isar Schemas**: Do not forget to run `dart run build_runner build` after modifying any entity.
- **X/Twitter Parsing**: Always use the `fixupx.com` routing logic in `MetadataService` to avoid 403 or empty OGP from X.
- **UI Design**: Maintain "Premium minimalist" style. Use `PhosphorIcons` for all icons. Avoid default Material colors; use the category's `accentColor`.
- **Haptics**: `HapticFeedback.lightImpact()` or `heavyImpact()` is used for critical actions (delete, long press).

## 8. Immediate Next Tasks for Codex
1. **Optimize YouTube Viewer**: Refine the vertical scroll experience in `YoutubeViewerScreen` to handle different YouTube formats (Shorts vs Regular) and ensure seamless auto-play.
2. **Implement Scroll/Navigation Locking**: Add logic to the vertical viewer to prevent the OS "swipe to go back" from interrupting the video experience.
3. **Refine AI Sub-Categorization**: Update `AddBookmarkSheet` to automatically apply the AI's `autoSubCategory` if the confidence is high, rather than just suggesting it.
