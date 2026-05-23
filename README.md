# Face2Mood

A mobile application that leverages real-time face detection and deep learning to analyze emotional expressions and track mood patterns over time. The app captures your face, predicts emotional states through AI, and maintains a personal mood history with statistical analysis.

## Overview

Face2Mood is built to understand emotional patterns by combining two specialized AI models: Google's ML Kit for accurate face detection and localization, paired with a custom RS-Xception emotion recognition model. The application processes everything locally on your device, ensuring your data never leaves your phone.

The core purpose is simple yet powerful: detect emotional expressions from faces in real-time, save mood records with context and personal notes, and visualize emotional trends through comprehensive statistics and charts.

## Key Features

**Real-time Face Detection and Emotion Analysis**
- Captures live camera feed and detects faces with precision
- Validates that only one person is in frame and ensures the entire face is visible
- Intelligently crops the detected face with context padding suitable for emotion recognition
- Checks lighting conditions to ensure accurate predictions
- Provides instant emotional predictions with confidence scores

**Multi-Emotion Tracking**
- Returns top 3 emotion predictions with individual confidence percentages
- Supports 7 emotion categories: happy, sad, angry, fear, disgust, neutral, and surprise
- Generates blended colors representing the dominant emotion for visual context

**Personal Mood Records**
- Save detected emotions with optional descriptions and personal notes (up to 30 words)
- Link emotions to different people (yourself, family members, colleagues)
- Each record captures the model prediction, your personal belief about the emotion, and custom notes
- Timestamps automatically recorded for every capture

**Comprehensive Statistics Dashboard**
- View emotional presence distribution across all your data
- Filter statistics by person and time range (all time, 1 day, 1 week, 1 month, 1 year)
- Three distinct statistical views:
  - Average Signals: Weighted average of top-3 emotion predictions
  - Top Prediction Count: Distribution of primary emotions detected
  - User vs Model Agreement: Comparison between your perception and the AI prediction
- Interactive pie charts with percentage breakdowns and detailed history lists
- Expandable mood entries with full details and one-tap deletion

**Complete Privacy**
- All processing happens on your device
- No cloud connectivity or external API calls for sensitive data
- Local SQLite database stores your entire mood history
- Automatic data management with clean database schema

## Technology Stack

**Frontend & Framework**
- Flutter with Dart for cross-platform mobile development
- Material Design with custom dark theme (Color: #0F0E17)
- Responsive UI with smooth animations and transitions

**Machine Learning**
- TensorFlow Lite with RS-Xception emotion recognition model (48x48 input)
- Google ML Kit Face Detection for precise facial localization
- Image preprocessing: grayscale conversion, resizing, contrast adjustment
- Confidence scoring via softmax output normalization

**Data Management**
- SQLite (via sqflite) for persistent local storage
- Structured schema with mood records and people management
- Automatic people tracking based on mood associations

**Supporting Libraries**
- Camera package for live video stream capture
- Image package for pixel-level image manipulation
- Path Provider for system directory access
- FL Chart for interactive pie chart visualizations
- Intl for timestamp formatting

## Architecture

The application follows a clean service-based architecture:

```
lib/
├── main.dart                          # App entry point, theme configuration
├── main_navigation.dart               # Bottom tab navigation
├── home_screen.dart                   # Live capture, real-time predictions, mood saving
├── stats_screen.dart                  # Statistical analysis and visualization
├── profile_screen.dart                # User settings and data management
└── services/
    ├── camera_service.dart            # Camera initialization and lifecycle
    ├── model_service.dart             # TensorFlow Lite emotion model inference
    ├── face_detection_MLKit_service.dart  # Face detection and intelligent cropping
    ├── database_service.dart          # SQLite database operations and sync
    └── mood_record_service.dart       # MoodRecord data model and serialization
```

**Core Components**

*HomeScreen* - The primary interface where users capture faces in real-time. It manages camera state, orchestrates the face detection and emotion model services, displays live predictions with confidence scores, and handles the mood saving workflow with a modal bottom sheet for capturing context.

*StatsScreen* - Analyzes the accumulated mood history with flexible filtering and multiple statistical perspectives. It calculates emotional distributions, processes user-vs-model agreement metrics, and renders interactive visualizations with detailed historical logs.

*ProfileScreen* - Provides access to privacy information and data management controls, emphasizing the local-first nature of the application.

*Services* - Each service encapsulates a distinct responsibility:
- **CameraService**: Abstracts camera initialization and delivers image frames
- **EmotionModelService**: Loads the TensorFlow Lite model and runs inference on preprocessed images
- **FaceDetectionService**: Implements sophisticated face detection logic including cropping with adaptive padding, "whole face" validation, lighting checks, and edge boundary enforcement
- **DatabaseService**: Implements the singleton pattern for SQLite management with versioning and migration support
- **MoodRecord**: Defines the data structure and serialization for mood entries

## Database Schema

The application uses a simple but effective two-table schema:

```
moods table:
- id (INTEGER PRIMARY KEY)
- timestamp (TEXT - ISO8601)
- primaryEmotion, secondEmotion, thirdEmotion (TEXT)
- confidence, secondConfidence, thirdConfidence (REAL)
- blendedColorHex (TEXT - emotion visualization color)
- personName (TEXT - who this emotion belongs to)
- userDescription (TEXT - user's note, max 30 words)
- userDominantEmotion (TEXT - what user believed they felt)

people table:
- id (INTEGER PRIMARY KEY)
- name (TEXT UNIQUE - distinct persons)
```

The database schema evolves gracefully through version migrations, handling legacy data and adding new columns as needed.

## Getting Started

### Prerequisites
- Flutter 3.10.7 or higher
- An Android or iOS device with a camera
- Basic familiarity with Flutter development

### Installation

Clone the repository:
```bash
git clone https://github.com/LucaSandru/Face2Mood.git
cd Face2Mood
```

Install dependencies:
```bash
flutter pub get
```

Run the application:
```bash
flutter run
```

### Model Files
The RS-Xception emotion recognition model (RSX_V2_mobile_safe.tflite) should be placed in:
```
assets/models/RSX_V2_mobile_safe.tflite
```

The model expects a 48x48 grayscale input and outputs 7 emotion probabilities.

## How It Works

**Capture Flow**
1. User opens the app and navigates to the home screen
2. Camera feed displays live preview with instructions
3. User positions their face in the frame
4. App taps to capture the current frame
5. Face detection validates that exactly one complete face is visible and lighting is adequate
6. Detected face is intelligently cropped with padding optimized for emotion recognition
7. Cropped image is sent to the emotion model for inference

**Emotion Prediction**
1. The emotion model preprocesses the cropped image (convert to grayscale, resize to 48x48)
2. TensorFlow Lite interpreter runs inference
3. Raw probabilities are returned for all 7 emotions
4. Top 3 results are selected with confidence scores
5. A blended color is generated representing the dominant emotion
6. Results displayed to user with confidence percentages

**Saving Mood Records**
1. After prediction, a bottom sheet modal appears
2. User selects or creates a person context
3. User optionally adds a description (word count validated)
4. User selects their believed emotion from a dropdown
5. On confirmation, the mood record is saved to the local database
6. People list automatically syncs with the recorded data
7. Success confirmation shown to user

**Statistics Processing**
1. All mood records are retrieved from the database
2. Records are filtered by selected person and time range
3. Based on the chosen statistic type, calculations are performed:
   - **Average Signals**: Weighted sum of top-3 confidences per emotion
   - **Top Prediction Count**: Simple frequency count of primary emotions
   - **User vs Model Agreement**: Comparison of user's believed emotion vs model's top-3
4. Pie chart is rendered with each section colored by emotion
5. Recent history is displayed with expandable details

## File Structure

The assets folder contains test images for development and validation:
```
assets/
└── test/
    ├── happy/uncropped/
    ├── angry/uncropped/
    ├── disgust/uncropped/
    ├── fear/uncropped/
    ├── neutral/uncropped/
    ├── sad/uncropped/
    └── surprise/uncropped/
```

These are organized by emotion category for model testing and performance evaluation.

## Privacy and Security

Face2Mood is designed with privacy as a foundational principle:

- **No Cloud Connectivity**: All emotion predictions and facial analysis happen entirely on your device. No images or predictions are transmitted to external servers.
- **Local Storage Only**: Your mood history, personal notes, and associated data are stored exclusively in your phone's local SQLite database.
- **No Tracking**: The app contains no analytics, telemetry, or third-party tracking services.
- **User Control**: You can permanently delete your entire mood history at any time through the profile settings.

## Performance Considerations

- Face detection uses "fast" mode prioritization for real-time performance
- The emotion model runs on 2 CPU threads for efficient inference
- Image preprocessing (grayscale, resize) is optimized for speed
- Camera frames are processed on-demand rather than continuously
- Database queries are indexed on timestamp for fast historical lookups

## Future Enhancements

Potential improvements for future versions:
- Batch emotion tracking for longer observation periods
- Export mood history as CSV or PDF reports
- Customizable emotion categories
- Integration with phone calendar for contextual mood tracking
- Social sharing of anonymized mood statistics
- Mood prediction based on time of day or calendar events

## Contributing

This project was developed as a personal research application. While contributions are welcome, please open an issue first to discuss proposed changes.

## License

This project is open source. Check the repository for license details.

## Acknowledgments

- Google ML Kit for robust face detection capabilities
- TensorFlow Lite for efficient on-device machine learning
- Flutter community for excellent cross-platform tooling
- The image processing and charting libraries that made this project possible
