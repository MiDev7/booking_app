# Booking App

A desktop application for managing appointments and bookings, built with Flutter.

## Features

- **Appointment Scheduling:** Book, view, and manage appointments across different time slots and days.
- **Location-Specific Bookings:** Manage appointments for different locations (e.g., Port-Louis, Quatre-Bornes), with distinct settings and color themes for each.
- **Weekly View:** Display appointments in a weekly table format, showing weekdays and Saturday.
- **Patient Management:** Record patient names for appointments.
- **Search Functionality:** Search for appointments by patient name.
- **Customizable Theming:**
  - Change the application's seed color.
  - Set different theme colors based on the selected location.
  - Customize colors for table rows.
- **Printing:**
  - Print individual appointment slips.
  - Print daily appointment lists.
  - Customize print label dimensions (width, height, unit) and select a printer.
- **Holiday Management:** Add and manage holidays, which are then visually indicated in the booking table.
- **Data Management:**
  - Data stored locally using SQLite.
  - Backup and restore database functionality.
- **Password Protection:** Secure access to certain settings (e.g., changing the default location for a week).
- **Desktop Focused:** Optimized for desktop usage with support for Windows, Linux, and macOS.

## Platforms Supported

- Windows
- Linux
- macOS

## Getting Started

### Prerequisites

- Flutter SDK: Make sure you have Flutter installed. Refer to the [official Flutter documentation](https://docs.flutter.dev/get-started/install) for installation instructions.
- An IDE like VS Code or Android Studio with the Flutter plugin.

### Setup

1.  **Clone the repository (if applicable) or open the project folder.**
2.  **Get dependencies:**
    ```sh
    flutter pub get
    ```

## How to Run

Ensure you have a connected device or an emulator/simulator running for the desired platform, or that your desktop environment is configured for Flutter development.

```sh
flutter run
```

To run on a specific desktop platform:

- **Windows:**
  ```sh
  flutter run -d windows
  ```
- **Linux:**
  ```sh
  flutter run -d linux
  ```
- **macOS:**
  ```sh
  flutter run -d macos
  ```

## How to Build

To create a release build for a specific platform:

- **Windows:**

  ```sh
  flutter build windows
  ```

  The executable will be located in `build\windows\x64\runner\Release\`. An installer can be created using the Inno Setup script in the installers directory.

- **Linux:**

  ```sh
  flutter build linux
  ```

  The application bundle will be located in `build/linux/<arch>/release/bundle/`.

- **macOS:**
  ```sh
  flutter build macos
  ```
  The application bundle will be located in Release.
