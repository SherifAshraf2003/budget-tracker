# EUI Budget Tracker

A comprehensive Flutter budget tracking app with AI-powered financial insights.

## Features

- 📊 **Expense Tracking**: Record and categorize your spending
- 🎯 **Budget Management**: Set monthly budgets for different categories
- 📈 **Reports & Analytics**: Visual spending reports and trends
- 🤖 **AI Financial Insights**: Get personalized financial advice powered by Llama 4 Scout
- 🔐 **Secure Authentication**: Firebase Auth integration
- 💾 **Cloud Storage**: Real-time data sync with Firestore

## Setup Instructions

### Prerequisites

- Flutter SDK (latest stable version)
- Firebase account
- OpenRouter API account (for AI insights)

### Environment Variables Setup

⚠️ **Important**: Never commit API keys to version control!

1. Copy the environment template:

   ```bash
   cp .env.example .env
   ```

2. Get your OpenRouter API key:

   - Visit [OpenRouter.ai](https://openrouter.ai/)
   - Sign up/login and get your API key
   - The key format: `sk-or-v1-xxxxxxxxxx`

3. Edit the `.env` file:
   ```
   OPENROUTER_API_KEY=your_actual_api_key_here
   ```

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Set up Firebase (follow Firebase docs)
4. Configure environment variables (see above)
5. Run the app:
   ```bash
   flutter run
   ```

## Security Best Practices

✅ **Implemented Security Measures:**

- **Environment Variables**: API keys stored in `.env` file
- **GitIgnore Protection**: `.env` file excluded from version control
- **Runtime Validation**: API key presence checked at runtime
- **Error Handling**: Graceful failure when API key is missing

⚠️ **Additional Recommendations:**

- Regularly rotate your API keys
- Use different API keys for development/production
- Monitor API usage and set spending limits
- Consider implementing server-side proxy for production apps

## Architecture

- **State Management**: Riverpod
- **Database**: Firebase Firestore
- **Authentication**: Firebase Auth
- **AI Integration**: OpenRouter API (Llama 4 Scout)
- **UI**: Material Design with custom theming
