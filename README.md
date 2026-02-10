# MiniMate

MiniMate is a digital companion for mini golf businesses — designed to modernize the course experience with digital scorekeeping, leaderboards, and customer insights.

## Quick Summary

- Digital scorecards and automated scoring
- Live leaderboards and player stats
- Business dashboard for insights and promotions
- Built with modern iOS technologies and Firebase backend

## Features

### For Players

- Instant access via QR codes
- Digital scorecards with automatic scoring
- Live leaderboards to compete locally or globally
- Personal game stats and achievements

### For Businesses

- Branded experience with course details and assets
- Customer insights dashboard (play trends, engagement)
- Promotions, seasonal campaigns, and optional ads
- Leaderboard management and event features

## Tech Stack

- App: SwiftUI, SwiftData
- Backend: Firebase (Auth, Firestore, Functions) and/or custom APIs
- Analytics: Apple App Analytics, custom metrics

## Architecture Overview

1. Player device scans a QR code at the course and opens the app.
2. The app records game data and updates live leaderboards via the backend.
3. Course owners view aggregated metrics and manage promotions through a web dashboard.

## Getting Started (for developers)

1. Open the Xcode workspace: MiniMate.xcworkspace
2. Install CocoaPods or Swift packages if used by your environment.
3. Configure Firebase by adding `GoogleService-Info.plist` to the appropriate targets.
4. Select a scheme (MiniMate or MiniMate Manager) and run on a device or simulator.

Notes:
- Ensure you have an Apple Developer account configured in Xcode for device testing.
- For production analytics and backend features, configure Firebase project settings and authentication.

## Contributing

- Fork the repo and open a PR for changes
- Follow the existing Swift style and project structure
- Add tests where applicable and run the project locally before submitting

## License & Contact

This project is maintained privately. For questions or access, contact the maintainer.

---

If you'd like, I can also: add a short development checklist, include example env files, or update the `functions/package.json` scripts. Which would you like next?
