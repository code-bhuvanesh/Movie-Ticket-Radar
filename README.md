# 🎟️ Ticket Radar

**Ticket Radar** is a cross-platform Flutter application (Android & Windows) designed to help you catch movie tickets before they sell out. It monitors cinema booking availability in the background and notifies you the moment tickets open up.

![App Screenshot](assets/app_icon.png)
*(Add screenshots of your app here)*

## ✨ Features

- **Background Monitoring**: Runs efficiently in the background to check for tickets periodically (every 15 minutes).
    - **Android**: Uses a persistent foreground service to ensure reliability even when the app is closed.
    - **Windows**: Minimized to system tray monitoring.
- **Smart Notifications**:
    - **Android**: High-priority alerts with sound when tickets are found.
    - **Windows**: Native toast notifications.
- **Granular Control**:
    - Filter by **Date** (Specific dates).
    - Filter by **Time Range** (e.g., 6 PM - 11 PM).
    - Monitor specific **Theatres** or all theatres in a city.
    - Watch for specific statuses (e.g., "Available" or "Filling Fast").
- **User Experience**:
    - Clean, modern UI with Dark/Light mode support.
    - "Live" tab to view real-time show listings.
    - City selection and management.

## 📱 Screenshots


<div align="center">
  <img src="assets/screenshot_tasks.png" width="30%" alt="Tasks Screen" />
  <img src="assets/screenshot_live.png" width="30%" alt="Live Availability" />
  <img src="assets/screenshot_notifications.png" width="30%" alt="Notifications" />
</div>

| Monitoring Tasks | Live Availability | Smart Notifications |
|:---:|:---:|:---:|
| Create complex filters | View real-time seats | Get notified instantly |


## 📥 Downloads

Get the latest Android APK and Windows Setup from the [Releases](../../releases) page.

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
- Android Studio / VS Code setup.

### Installation

```bash
# Clone the repository
git clone https://github.com/code-bhuvanesh/Ticket-Radar.git

# Go to the project directory
cd ticket_radar

# Install dependencies
flutter pub get

# Run the app
flutter run
```


## Disclaimer

**This project is for educational purposes only.**

- This application interacts with third-party cinema booking services to monitor data.
- **Ticket Radar** is an independent project and is **not** affiliated with, endorsed by, or connected to PVR Cinemas or any other cinema chain.
- The developers are not responsible for any misuse of this tool, strictly for personal non-commercial monitoring.
- Use of this software is at your own risk.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
