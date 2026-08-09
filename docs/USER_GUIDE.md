# QueueWise User Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Customer Features](#customer-features)
4. [Admin Features](#admin-features)
5. [Troubleshooting](#troubleshooting)

## Introduction

QueueWise is a smart queue management application that allows you to join virtual queues remotely, track your position in real-time, and receive notifications when your turn is approaching. This eliminates the need to wait physically in line, allowing you to use your time productively.

### Key Benefits
- **Remote Queue Joining**: Join queues from anywhere using your mobile device
- **Real-Time Tracking**: Monitor your queue position and estimated waiting time
- **Push Notifications**: Get notified when your turn is approaching
- **Queue History**: View your past queue visits
- **No Physical Waiting**: Avoid crowded waiting areas

## Getting Started

### Installation

1. **Download the App**
   - Android: Download the APK from the provided link
   - iOS: Download from the App Store (when published)
   - Web: Access via browser at the provided URL

2. **Launch the App**
   - Open QueueWise on your device
   - You will see the login screen

### Registration

1. **Create an Account**
   - Tap "Sign Up" on the login screen
   - Enter your full name
   - Enter your email address
   - Create a password (minimum 6 characters)
   - Tap "Register"

2. **Verify Your Email** (if enabled)
   - Check your email inbox for a verification link
   - Click the link to verify your account
   - Return to the app and log in

### Login

1. **Sign In**
   - Enter your registered email address
   - Enter your password
   - Tap "Login"

2. **Forgot Password**
   - Tap "Forgot Password?" on the login screen
   - Enter your email address
   - Check your email for password reset instructions

## Customer Features

### Browsing Organisations

1. **View Organisation List**
   - After logging in, you'll see a list of available organisations
   - Each organisation shows its name and status

2. **Search for an Organisation**
   - Use the search bar at the top
   - Type the organisation name
   - Results will filter in real-time

3. **Select an Organisation**
   - Tap on any organisation card
   - You'll see the available services for that organisation

### Selecting Services

1. **View Available Services**
   - After selecting an organisation, you'll see a list of services
   - Each service shows its name and description

2. **Choose a Service**
   - Tap on the service you need
   - Review the service details
   - Tap "Join Queue" to proceed

### Joining a Queue

1. **Confirm Queue Join**
   - After selecting a service, tap "Join Queue"
   - The system will generate a unique token number for you
   - You'll see your token number and estimated waiting time

2. **View Your Token**
   - Your token number will be displayed (e.g., A-001)
   - You'll see your current position in the queue
   - Estimated waiting time is shown based on current queue length

### Tracking Your Queue

1. **Live Queue Screen**
   - View your current position in real-time
   - See the currently serving token number
   - Monitor estimated waiting time
   - The screen updates automatically as the queue progresses

2. **Queue Status Indicators**
   - **Waiting**: Your turn is pending
   - **Called**: Your token has been called
   - **Serving**: Your turn is currently being served
   - **Served**: Your turn has been completed
   - **Cancelled**: You cancelled your token
   - **No Show**: You missed your turn

### Cancelling Your Token

1. **Cancel from Active Queue Screen**
   - Tap the "Cancel" button on the active queue screen
   - Confirm the cancellation
   - Your token will be removed from the queue

2. **Why Cancel?**
   - If you no longer need the service
   - If you can't make it to your appointment
   - To allow others to move up in the queue

### Viewing Queue History

1. **Access History**
   - Navigate to the "History" section from the main menu
   - You'll see a list of your past queue visits

2. **History Details**
   - Each entry shows:
     - Organisation name
     - Service type
     - Token number
     - Date and time
     - Status (served, cancelled, no-show)
     - Waiting duration

### Receiving Notifications

**Note**: Push notifications are not included in this version to avoid requiring the Firebase Blaze plan. Users should check the app regularly for queue updates. This feature can be added in future iterations.

## Admin Features

### Accessing Admin Dashboard

1. **Admin Login**
   - Log in with your admin credentials
   - Your account must have "admin" role assigned
   - The admin dashboard will be accessible from the main menu

2. **Dashboard Overview**
   - View all organisations you manage
   - See active queue status for each organisation
   - Access queue management tools

### Managing Queues

1. **View Active Queue**
   - Select an organisation from the dashboard
   - View the current queue with all tokens
   - See token status for each customer

2. **Call Next Token**
   - Tap "Call Next" to advance the queue
   - The next waiting customer will be marked as "called"
   - A push notification will be sent to that customer

3. **Mark as Serving**
   - When a customer arrives at the counter
   - Tap "Mark as Serving"
   - The token status changes to "serving"

4. **Mark as Served**
   - When service is completed
   - Tap "Mark as Served"
   - The token status changes to "served"
   - Analytics will be updated automatically

5. **Mark as No Show**
   - If a customer doesn't arrive after being called
   - Tap "Mark as No Show"
   - The token status changes to "no-show"
   - Analytics will track no-show rates

### Viewing Analytics

1. **Access Analytics**
   - Navigate to the "Analytics" section from the admin dashboard
   - View performance metrics for your services

2. **Available Metrics**
   - **Total Served**: Number of customers served
   - **Total Cancelled**: Number of cancellations
   - **Total No Show**: Number of no-shows
   - **Average Wait Time**: Average time customers wait
   - **Average Service Time**: Average time to serve each customer
   - **Completion Rate**: Percentage of tokens served
   - **No Show Rate**: Percentage of no-shows
   - **Peak Hour**: Busiest time of day

3. **Date Range Filtering**
   - Filter analytics by date range
   - View daily, weekly, or monthly statistics
   - Export data for reporting

## Troubleshooting

### Common Issues

**Issue: App won't load**
- Solution: Check your internet connection
- Solution: Close and reopen the app
- Solution: Clear app cache and restart

**Issue: Can't log in**
- Solution: Verify your email and password are correct
- Solution: Reset your password if needed
- Solution: Check if your account is verified

**Issue: Queue not updating**
- Solution: Pull to refresh on the queue screen
- Solution: Check your internet connection
- Solution: Close and reopen the app

**Issue: Not receiving notifications**
- Solution: Enable notifications in device settings
- Solution: Check if the app has notification permissions
- Solution: Ensure you're logged in

**Issue: Can't join queue**
- Solution: Verify the organisation and service are active
- Solution: Check if you already have an active token
- Solution: Contact support if the issue persists

### Contact Support

If you encounter issues not covered in this guide:
- Email: support@queuewise.com
- Include your user ID and a description of the issue
- Our team will respond within 24 hours

### Tips for Best Experience

1. **Enable Notifications**
   - Always keep notifications enabled for timely updates

2. **Check Your Position Regularly**
   - Monitor your queue position to know when to arrive

3. **Cancel if Unnecessary**
   - Cancel your token if you can't make it to help others

4. **Arrive on Time**
   - When notified, arrive promptly to avoid being marked as no-show

5. **Keep App Updated**
   - Always use the latest version of the app for best performance

## Privacy and Security

### Data Protection
- Your personal information is encrypted and stored securely
- Your queue history is private and only accessible to you
- We do not share your data with third parties

### Account Security
- Use a strong, unique password
- Don't share your login credentials
- Log out after using shared devices

## Version History

- **Version 1.0.0** - Initial release with core features
  - User registration and authentication
  - Organisation and service browsing
  - Virtual queue joining
  - Real-time queue tracking
  - Push notifications
  - Queue history
  - Admin dashboard
  - Analytics module

## Support

For additional help or feedback:
- **Email**: support@queuewise.com
- **Website**: www.queuewise.com
- **Documentation**: docs.queuewise.com

---

**QueueWise Team**  
Noble Stars - HDIT 21143  
International Campus of Science and Technology
