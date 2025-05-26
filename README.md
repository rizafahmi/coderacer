# Coderacer

A **CodeRacer** typing speed game designed for developers to practice typing code snippets in various programming languages. Challenge yourself with AI-generated code snippets across different difficulty levels and track your typing performance.

## 🚀 Features

- **AI-Generated Code Challenges**: Dynamic code snippets generated using GenAI
- **Multiple Programming Languages**: Support for various programming languages (JavaScript, Python, Elixir, etc.)
- **Difficulty Levels**: Easy, Medium, and Hard challenges to match your skill level
- **Real-time Typing Interface**: Live feedback as you type with streak tracking
- **Performance Analytics**: Track your typing speed (Character Per Second), accuracy, streaks, and errors

## 🎯 How It Works

1. **Choose Your Challenge**: Select a programming language and difficulty level
2. **Start Typing**: Type the AI-generated code snippet as accurately and quickly as possible
3. **Track Performance**: Monitor your characters per second (CPS), streak count, and error rate
4. **View Results**: See detailed statistics after completing each session

## 🛠️ Tech Stack

- **Backend**: Elixir & Phoenix Framework
- **Frontend**: Phoenix LiveView, Tailwind CSS, DaisyUI
- **Database**: SQLite with Ecto
- **AI Integration**: GenAI for code generation
- **Real-time Updates**: Phoenix LiveView for reactive user interface

## 🚀 Getting Started

### Prerequisites

- Elixir 1.15 or later
- Erlang/OTP 24 or later
- Node.js (for asset compilation)
- GenAI API key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd coderacer
   ```

2. **Set up environment variables**
   ```bash
   cp .envrc-example .envrc
   # Edit .envrc and add your GEMINI_API_KEY
   ```

3. **Install dependencies and setup**
   ```bash
   mix setup
   ```
   This command will:
   - Install Elixir dependencies
   - Create and migrate the database
   - Install and build assets (Tailwind CSS, esbuild)

4. **Start the Phoenix server**
   ```bash
   mix phx.server
   ```
   Or inside IEx with:
   ```bash
   iex -S mix phx.server
   ```

5. **Visit the application**
   Open [`http://localhost:4000`](http://localhost:4000) in your browser

## 📖 Usage

### Starting a Game

1. Navigate to the home page
2. Select your preferred programming language
3. Choose a difficulty level (Easy, Medium, or Hard)
4. Click "Start Game" to generate a code challenge

### Playing the Game

- Type the displayed code as accurately as possible
- Your typing speed (CPS) and accuracy are tracked in real-time
- Consecutive correct characters build your streak
- Incorrect characters are counted as errors

### Viewing Results

After completing a session, you'll see:
- **CPS (Characters Per Second)**: Your typing speed
- **Streak**: Longest sequence of correct characters
- **Errors**: Total number of typing mistakes
- **Completion Time**: Total time taken to complete the challenge

## 🔧 Development

### Available Commands

- `mix setup` - Install dependencies and setup the project
- `mix check` - Run code quality checks (formatting and linting)
- `mix test` - Run the test suite
- `mix phx.server` - Start the development server
- `mix ecto.reset` - Reset the database

### Code Quality

This project uses several tools to maintain code quality:
- **Credo**: Static code analysis
- **Dialyzer**: Type checking
- **ExUnit**: Testing framework
- **Phoenix LiveReload**: Automatic browser refresh during development

Run all quality checks with:
```bash
mix check
```

## 🤝 Contributing

We welcome contributions to Coderacer! Here's how you can help:

### Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Development Workflow

1. **Make your changes** following the existing code style
2. **Add tests** for new functionality
3. **Run quality checks**:
   ```bash
   mix check
   ```
4. **Ensure tests pass**:
   ```bash
   mix test
   ```
5. **Commit your changes** with descriptive commit messages
6. **Push to your fork** and create a pull request

### Code Style Guidelines

- Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Use descriptive variable and function names
- Add documentation for public functions
- Write tests for new features and bug fixes
- Use keyword-based Ecto queries when possible

