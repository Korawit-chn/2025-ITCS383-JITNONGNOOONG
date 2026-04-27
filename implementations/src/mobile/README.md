# JITNONGNOONG Mobile App

A Flutter mobile application for the JITNONGNOONG dog adoption platform.

## Features

- User authentication (login/register)
- Browse available dogs
- User dashboard with adoption requests, favourites, checkups, pickup
- Staff dashboard for managing adoptions, appointments, checkups, dogs, verification
- Admin dashboard for system management
- Sponsor dashboard for sponsorship management

## Setup

1. Ensure Flutter SDK is installed
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## Backend

The app connects to the existing Node.js backend at `http://localhost:3000`

## Architecture

- Provider for state management
- HTTP for API calls
- SharedPreferences for local storage
- Material Design UI