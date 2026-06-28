# Face2Mood: Mobile Emotion Recognition System

Face2Mood is a lightweight Android application for real-time **Facial Emotion Recognition** (FER) developed using _Flutter, Google ML Kit, TensorFlow Lite_, and _SQLite_. The application performs automatic face detection, facial emotion recognition, local mood tracking, and statistical visualization entirely on-device, eliminating the need for cloud-based processing while preserving user privacy.

---

## Project Context

This project was developed as part of a Bachelor's Thesis in Computer Science at the **West University of Timișoara**.

The objective of the project was to design, implement, and evaluate a complete mobile Facial Emotion Recognition system capable of performing real-time emotion analysis directly on Android smartphones. The proposed solution combines a lightweight Deep Learning model based on the **RS-Xception** architecture with Google ML Kit for face detection and TensorFlow Lite for efficient on-device inference. All emotion recognition operations are executed locally, ensuring low computational requirements and maintaining user privacy without relying on external servers.

---

## Repository Highlights

- **Complete Android application** implementing an **end-to-end Facial Emotion Recognition pipeline**.
- **Lightweight RS-Xception** Deep Learning model optimized for **TensorFlow Lite deployment**.
- **Real-time on-device** emotion recognition using the **smartphone camera**.
- **Automatic face detection** and preprocessing using **Google ML Kit**.
- **Local SQLite database** for storing **emotion history and user feedback**.
- **Interactive statistical dashboards** for emotion distribution and prediction analysis.
- **Fully offline operation** without Internet connectivity or **cloud inference**.
- **Jupyter notebooks** containing the complete **model development and training pipeline**.
- **Ready-to-install Android APK** for deployment on **physical devices**.

---

## Main Features

- **Real-time Facial Emotion Recognition** directly on Android devices.
- **Automatic Face Detection** using Google ML Kit before model inference.
- **Recognition of Seven Basic Emotions**: Angry, Disgust, Fear, Happy, Neutral, Sad, and Surprise.
- **Top-3 Emotion Predictions** together with confidence scores for each captured image.
- **Emotion Interpretation** through color-based feedback and personalized suggestions.
- **Local Mood History** stored securely in a SQLite database.
- **Interactive Statistics Dashboard** presenting emotion distribution, dominant emotions, and user–model agreement.
- **Privacy-Oriented Design**, where all image processing, inference, and data storage are performed entirely on the user's device.

---

## How to Use Face2Mood

After launching the application, follow these steps:

### Step 1 — Position Your Face
- Hold the smartphone approximately 30–50 cm from your face.
- Ensure your face is fully visible within the frame.
- Use good lighting conditions.
- Look directly at the camera.

### Step 2 — Capture an Emotion
Press the **Capture** button. The application will:
1. Detect the face using Google ML Kit.
2. Crop and preprocess the facial region.
3. Run the TensorFlow Lite model.
4. Display the Top-3 predicted emotions.

### Step 3 — View Detailed Analysis
Tap **More Info** to access:
- Confidence scores and emotional color palette.
- Emotion interpretation based on the predicted emotion.
- Personalized emotion-aware interpretations/suggestions.

### Step 4 — Save the Result
Press **Save to Stats** to store the emotion record locally.

### Step 5 — Explore Statistics
Open the **Stats** page to view:
- Emotion distribution and most frequent emotions.
- User-model agreement metrics.
- Complete mood history.

### Step 6 — Manage Your Profile
The **Profile** page allows you to:
- View privacy information.
- Clear local mood history.
- Read application details.

> **Note:** All information remains stored locally on the device.

---

## Application Workflow

```text
Launch Application
        │
        ▼
Initialize Camera
        │
        ▼
```

<img src="docs/app_screenshots/home_screen.png" width="200" />

```text
        │
        ▼
Google ML Kit Face Detection
        │
        ▼
   Face Cropping
        │
        ▼
48×48 Grayscale Conversion
        │
        ▼
TensorFlow Lite Inference
        │
        ▼
```

<img src="docs/app_screenshots/button_prediction.png" width="200" />

```text
        │
        ▼
Top-3 Emotion Predictions
        │
        ▼
Emotion Interpretation
        │
        ▼
```

<img src="docs/app_screenshots/emotional_pallete(more info).png" width="200" />

```text
        │
        ▼
Optional Save to SQLite
        │
        ▼
Statistics Dashboard
        │
        ▼
```

<img src="docs/app_screenshots/stats_menu.jpeg" width="200" />&nbsp;&nbsp;&nbsp;&nbsp;<img src="docs/app_screenshots/top_prediction_count.jpeg" width="200" />&nbsp;&nbsp;&nbsp;&nbsp;<img src="docs/app_screenshots/recent%20history%20-%20stats.png" width="200" />


```text
        │
        ▼
User Profile & Privacy
        │
        ▼
```

<img src="docs/app_screenshots/profile%20page(1).jpeg" width="200" />&nbsp;&nbsp;<img src="docs/app_screenshots/profile%20page(2).jpeg" width="200" />

---

## System Architecture

The diagram below illustrates the end-to-end **Face2Mood** workflow. Facial images are captured by the _smartphone camera_, processed using _Google ML Kit_ and _TensorFlow Lite_, and the resulting emotion predictions are stored locally in a _SQLite database_ for _visualization_ and _statistical analysis_.

<img src="assets/BSc%20Architeture.png" width="200" />



### Repository Structure
```text
Face2Mood/
├── assets/
│   └── models/              # Optimized TensorFlow Lite models (.tflite)
|   ├── download_app/        # .apk file for direct download
|   ├── notebooks/           # .ipynb notebooks for training in Google Colaboratory
|   ├── models_plots/        # plots from notebooks used in analysis for each model
|        ├── RS-Xception_v1/
|        ├── RS-Xception_v2/
|        ├── RS-Xception_v3/
|        ├── RS-Xception_v4/
|   ├── BSc Architeture.png  # archhitecture of the application
├── docs/
│   └── app_screenshots/         # UI/UX documentation images
|   ├── cropped_vs_uncropped/    
        ├── test/                # folder with images used in testing
        ├── results cropped vs. uncropped.xlsx   # details of the cropped vs. uncropped analysis
├── lib/                     # Flutter source code
│   ├── screens/             # Presentation Layer
│   │   ├── home/            # Real-time capture and inference interface
│   │   ├── stats/           # Analytics, data visualization, and history
│   │   └── profile/         # User profile and account management
│   ├── services/ 
│   │   ├── camera_service.dart             # Hardware abstraction
│   │   ├── database_service.dart           # SQLite persistence logic
│   │   ├── emotion_utils.dart              # Metadata (colors, interpretations)
│   │   ├── face_detection_mlkit_service.dart # Facial localization
│   │   ├── model_service.dart              # TFLite inference engine
│   │   └── mood_record.dart                # Data Transfer Objects (DTOs)
│   ├── main.dart            # Application entry point
│   └── main_navigation.dart # Centralized routing
├── research/                # AI Development (Jupyter Notebooks)
│   └── training_pipeline.ipynb # Model training & conversion logic
├── test/                    # Automated Verification & Validation (V&V)
│   ├── unit/                # Testing for individual service logic
│   └── integration/         # Database and data-flow verification tests
├── pubspec.yaml             # Project dependencies
└── README.md                # Project documentation
```

---

## Technologies & Requirements

### Core Technologies

- Flutter
- Dart
- TensorFlow Lite
- Google ML Kit
- SQLite
- fl_chart

### Requirements

- Android 5.0 (API 21) or later
- Flutter SDK
- Android Studio (recommended)

### Build

```bash
flutter pub get
flutter doctor
````

---

## Deep Learning Model Evaluation

The emotion recognition model is based on a lightweight **RS-Xception** architecture trained from scratch on the **FER-2013** dataset.

### Models Comparison

| Model | Accuracy | Precision | Recall | F1-Score | Parameters | Selected |
|:------|---------:|----------:|-------:|---------:|-----------:|:--------:|
| RSX_V1 | 35.83% | 32.50% | 39.90% | 32.60% | 514,600 | No |
| **RSX_V2** | **65.05%** | **63.40%** | **64.80%** | **63.80%** | **847,747** | **Yes** |
| RSX_V3 | 64.31% | 65.00% | 61.50% | 62.80% | 847,747 | No |
| RSX_V4 | 65.14% | 63.60% | 62.90% | 63.10% | 847,747 | No |

**Note:** Although RSX_V4 achieved a slightly higher test accuracy, RSX_V2 was selected for mobile deployment because it demonstrated the best balance across Precision, Recall, and F1-Score, alongside stable training behavior. The training logs, training plots, and evaluation metrics for all configurations are located in the `assets/models_plots/` folder.


### Model Performance Metrics

| Metric | Value |
|--------|-------|
| Selected Model | RSX_V2 (TFLite) |
| Validation Accuracy | 65.05% |
| Model Size | 0.91 MB |
| Inference Time | ~6.73 ms |
| Total End-to-End Time | ~513.97 ms |

### Cropped vs. Uncropped Analysis
Experimental results show that automatic face cropping using Google ML Kit significantly improves recognition performance by reducing background noise.

| Preprocessing Strategy | Top-1 Accuracy | Top-3 Accuracy |
|------------------------|--------------:|--------------:|
| Uncropped Images | 24.3% | 50.0% |
| Manually Cropped Faces | 37.1% | 68.6% |
| Automatically Cropped Faces | 42.9% | 77.1% |

**Note:** The complete analysis spreadsheet is available at `docs/cropped_vs_uncropped/results%20cropped%20vs.%20uncropped.xlsx`, and the evaluation dataset images are located in the `docs/cropped_vs_uncropped/test/` folder.


### Dataset & Training Configuration

**Dataset:** FER-2013

- Total images: **35,887**
- Training set: **28,709**
- Validation set (Public Test): **3,589**
- Test set (Private Test): **3,589**
- Image size: **48 × 48** grayscale
- Emotion classes: **7** (Angry, Disgust, Fear, Happy, Neutral, Sad, Surprise)


**Training Pipeline**:
1. **Data Preprocessing**: Normalization, augmentation (rotation, scaling, shifts)
2. **Model Architecture**: RS-Xception with depthwise separable convolutions
3. **Optimization**: Adam optimizer (lr=0.001)
4. **Loss Function**: Categorical Crossentropy
5. **Batch Size**: 32
6. **Epochs**: 100 (with early stopping at patience=15)

   
**Model Conversion**

- Framework: TensorFlow Lite
- Source model: Keras (.h5)
- Deployment format: `.tflite`
- Final model size: **0.91 MB**


**Full reproducible training code**: See `assets/notebooks/RS-XCeption_v2.ipynb`

---

## Limitations

The current version of **Face2Mood** inherits several limitations commonly associated with lightweight mobile Facial Emotion Recognition systems.

### Dataset Limitations

The model was trained on the **FER-2013** dataset, which presents several challenges:

- Class imbalance, particularly for minority emotions such as **Disgust** and **Fear**.
- Low-resolution grayscale images (48 × 48 pixels).
- Limited demographic diversity.
- Predominantly posed facial expressions that may differ from natural real-world emotions.

### Real-World Limitations

Recognition performance may decrease under challenging conditions, including:

- Poor or uneven lighting.
- Large head pose variations.
- Facial occlusions (e.g., glasses, masks, or partially visible faces).
- Motion blur or low-quality camera images.

Despite these limitations, the proposed system demonstrates reliable real-time performance while maintaining a lightweight architecture suitable for on-device deployment.

#### Future Directions

- **Alternative Architectures**: Investigate lightweight backbones, attention mechanisms, or hybrid neural approaches to improve accuracy while keeping mobile deployment efficient.
- **Explainable AI (XAI)**: Integrate techniques like Integrated Gradients (IG) into the *More Info* view to visualize high-activation facial regions and build user trust.
- **Video-Based Tracking**: Extend the framework from static image inference to continuous video tracking to analyze real-time emotional dynamics over time.
- **Interactive Assistance**: Evolve from a passive monitoring tool into an interactive emotional assistant by embedding conversational AI features and personalized feedback.


### Privacy Statement
- **No data transmission**: All processing remains strictly on-device
- **No cloud storage**: Biometric data never leaves the device
- **Offline functionality**: No Internet connection is required for the core functionality.
- **Local storage only**: Optional mood history stored in private SQLite database on the user's device
- **No third-party sharing**: Emotional data is never shared with external services or third parties

---

## Privacy & Architecture

- **On-Device Inference**: Biometric data is processed in-memory and immediately discarded after inference; no persistent storage of raw biometric data.
- **Local Storage**: All emotional history is stored in a private SQLite instance with no external synchronization.
- **Offline Functionality**: The application requires zero internet permissions for core functionality, fully adhering to "Privacy-by-Design" principles.
- **Data Minimization**: Only emotion predictions and timestamps are stored; raw facial images are never persisted.

---

## Testing & Validation

### Test Coverage

The test suite validates data models, calculations, and local storage:
- **Database operations**: Verifies data persistence, updates, and integrity across user records.
- **Statistical calculations**: Assures exact metrics processing for mood trends and probability spectrum distributions.
- **Core data models**: Validates serialization and data structures across the application pipeline.


### Run Tests

```bash
flutter test                    # Run all unit & integration tests
flutter test test/<PATH_TEST>        # Run a pecific unit test
```

---

## Getting Started

### Option A — Install the Application (APK)

The easiest way to try Face2Mood is to install the provided APK, which is present in `assets/download_app` folder.

1. **Download**: `app-arm64-v8a-release.apk` from the specified folder
2. **Transfer** the APK to your Android phone
3. **Enable Install from Unknown Sources** if prompted (Settings > Security)
4. **Install** the application
5. **Launch** Face2Mood and grant camera permissions

>  **No Internet connection is required**

### Option B — Run from Source

#### Requirements

- Flutter SDK 3.10.7+
- Android Studio 2022.1+
- Android SDK (API 21+)
- Physical Android device or emulator (2GB+ RAM recommended)
- Git

#### Setup

1. **Clone repository**:
   ```bash
   git clone https://github.com/LucaSandru/Face2Mood.git
   ```

2. **Enter project**:
   ```bash
   cd Face2Mood
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Verify Flutter installation**:
   ```bash
   flutter doctor
   ```
   Ensure all checks pass (at least Android Studio and Flutter should be green).

5. **Connect device** and verify:
   ```bash
   flutter devices
   ```

6. **Run application**:
   ```bash
   flutter run
   ```
   Or with debug symbols:
   ```bash
   flutter run -v
   ```

#### Build Release APK

```bash
flutter build apk --release --split-per-abi
```

Generated APK location: `build/app/outputs/flutter-apk/`

For arm64-v8a (most common):
```bash
flutter build apk --release --target-platform=android-arm64
```

---

## Model Training & Reproducibility

Full training pipeline details are provided in the Jupyter notebooks, which are in the `assets/notebooks`.


### Training Steps (presented into notebook)
1. Data loading and preprocessing (normalization, augmentation)
2. RS-Xception model architecture definition
3. Training with validation monitoring and class weighting
4. Hyperparameter tuning and early stopping
5. Model evaluation on test set with per-class performance analysis
6. TFLite conversion with dynamic range quantization
7. Performance verification on mobile hardware

---

## License

This project is provided for **educational purposes** as part of a Bachelor's thesis. Commercial use is not permitted without explicit permission.


---

## Related Publication

This repository accompanies the Bachelor's Thesis:

**Face2Mood: Mobile Emotion Recognition System**

Bachelor of Computer Science  
West University of Timișoara  
2026

---

## Support & Contact

For questions or issues related to this thesis project:

- **Author**: Luca-David Șandru
- **Institution**: West University of Timișoara
- **Program**: BSc Computer Science in English
- **Academic Year**: 2025-2026
- **Repository**: https://github.com/LucaSandru/Face2Mood

---

## Author

**Luca-David Șandru**  
Bachelor's Thesis Project  
Computer Science in English  
West University of Timișoara  
2026
