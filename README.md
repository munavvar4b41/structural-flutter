# Structural desktop (Flutter)

Cross-platform desktop client for Structural: system tray timer controls, pending task shortcuts, and a My Work kanban board backed by the Laravel desktop API.

## Requirements

- Flutter SDK 3.11+
- Laravel app running with desktop API routes (`/api/desktop/*`)
- Staff user **without** two-factor authentication (2FA accounts must use the web app)

### Linux build dependencies

`tray_manager` needs AppIndicator development headers at **build** time:

```bash
# Fedora
sudo dnf install libayatana-appindicator3-devel libsecret-devel

# Debian/Ubuntu
sudo apt install libayatana-appindicator3-dev libsecret-1-dev
```

After installing, run a clean rebuild: `flutter clean && flutter run -d linux`.

**Linux tray notes:** `setToolTip` is not supported by `tray_manager` on Linux (the app uses `setTitle` for the indicator label instead). The context menu opens from the tray icon click; no manual popup is required.

### Tray icon

Replace the placeholder at [`assets/icons/app.png`](assets/icons/app.png) with your own **64×64** PNG (high contrast works best on Linux panels). Restart the app after replacing.

The tray label shows the **running task title and elapsed time** (not "Structural") while a timer is active.

### macOS

Network client entitlement is included for API calls. Tray icon uses bundled assets.

### Windows

Runs in the notification area (system tray).

## Configuration

Default API base URL: `http://127.0.0.1:8000` (local `php artisan serve`).

Override at build/run time:

```bash
flutter run -d linux --dart-define=API_BASE_URL=https://structural.test
```

You can also change the URL in **Settings** inside the app (stored in secure storage).

## Run

From this directory:

```bash
flutter pub get
flutter run -d linux
```

On first launch, sign in with your Laravel email and password. The system tray icon appears and the **My Work** board opens.

- **Close window (X):** hides the window; the tray icon stays active.
- **Tray → View all tasks:** shows the My Work board.
- **Tray → Quit:** exits the application.

## Tray menu

When a timer is running:

- Header with truncated task title and elapsed time
- Stop, Pause/Resume, Refresh (icon menu items where supported)

**Project tasks**: up to **15** rows in the menu (assigned **To do** / **In progress**, active task excluded), each clickable to switch the timer. Status is shown as a prefix on each row. The native menu scrolls when the list is tall.

**My Work** task cards: **View**, **Start** / **Pause** / **Resume**, and **Stop** (pause ends the clock without closing the entry; stop closes the session).

## API endpoints used

| Method | Path |
|--------|------|
| POST | `/api/desktop/login` |
| POST | `/api/desktop/logout` |
| GET | `/api/desktop/tray` |
| GET | `/api/desktop/my-work` |
| POST | `/api/desktop/timer/start` |
| POST | `/api/desktop/timer/stop` |
| POST | `/api/desktop/timer/pause` |
| POST | `/api/desktop/timer/resume` |

## Build release

```bash
flutter build linux --dart-define=API_BASE_URL=https://your-production-host
flutter build windows --dart-define=API_BASE_URL=https://your-production-host
flutter build macos --dart-define=API_BASE_URL=https://your-production-host
```
