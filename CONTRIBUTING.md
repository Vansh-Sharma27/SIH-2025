# Contributing to YatraLive

First off, thank you for considering contributing to YatraLive! It's people like you that make YatraLive such a great tool for improving public transportation in India.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Process](#development-process)
- [Style Guidelines](#style-guidelines)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project and everyone participating in it is governed by the [YatraLive Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [project-maintainers@example.com](mailto:project-maintainers@example.com).

## Getting Started

### Prerequisites

- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Git
- A GitHub account
- Basic knowledge of Flutter/Dart

### Setting Up Your Development Environment

1. **Fork the repository**
   ```bash
   # Click the 'Fork' button on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/yourusername/YatraLive.git
   cd YatraLive
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/originalowner/YatraLive.git
   ```

4. **Install dependencies**
   ```bash
   cd yatra_live
   flutter pub get
   ```

5. **Run tests**
   ```bash
   flutter test
   ```

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Describe the behavior you observed and expected**
- **Include screenshots if possible**
- **Include your environment details** (OS, Flutter version, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested enhancement**
- **Provide specific examples to demonstrate the enhancement**
- **Describe the current behavior and expected behavior**
- **Explain why this enhancement would be useful**

### Your First Code Contribution

Unsure where to begin? Look for issues labeled:

- `good first issue` - Simple issues perfect for beginners
- `help wanted` - Issues where we need community help
- `documentation` - Documentation improvements

## Development Process

### Branching Strategy

We use Git Flow for our branching strategy:

```
main (production)
├── develop (main development)
│   ├── feature/your-feature-name
│   ├── bugfix/issue-description
│   └── hotfix/critical-fix
```

### Creating a Feature Branch

```bash
# Update your local develop branch
git checkout develop
git pull upstream develop

# Create your feature branch
git checkout -b feature/your-feature-name

# Make your changes
# ...

# Commit your changes
git add .
git commit -m "feat: add amazing feature"

# Push to your fork
git push origin feature/your-feature-name
```

## Style Guidelines

### Dart/Flutter Style Guide

We follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) and [Flutter Style Guide](https://docs.flutter.dev/development/ui/widgets-intro#basic-widgets).

Key points:
- Use `dartfmt` to format your code
- Maximum line length: 80 characters
- Use meaningful variable and function names
- Add comments for complex logic
- Write tests for new features

### Code Organization

```dart
// Good example
class BusTracker {
  // Constants first
  static const int updateInterval = 30;
  
  // Private fields
  final String _busId;
  Timer? _updateTimer;
  
  // Public fields
  late final LocationService locationService;
  
  // Constructor
  BusTracker(this._busId);
  
  // Public methods
  void startTracking() {
    // Implementation
  }
  
  // Private methods
  void _updateLocation() {
    // Implementation
  }
  
  // Dispose method last
  void dispose() {
    _updateTimer?.cancel();
  }
}
```

## Commit Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Test additions or corrections
- `build`: Build system changes
- `ci`: CI configuration changes
- `chore`: Other changes that don't modify src or test files

### Examples

```bash
# Feature
git commit -m "feat(driver): add break time management"

# Bug fix
git commit -m "fix(passenger): correct ETA calculation for traffic"

# Documentation
git commit -m "docs: update API documentation for location service"

# Performance
git commit -m "perf(map): optimize marker rendering for 100+ buses"
```

## Pull Request Process

### Before Submitting

1. **Update documentation** if you've changed APIs
2. **Add tests** for new functionality
3. **Run all tests** and ensure they pass
   ```bash
   flutter test
   flutter analyze
   ```
4. **Update CHANGELOG.md** with your changes
5. **Rebase on latest develop**
   ```bash
   git fetch upstream
   git rebase upstream/develop
   ```

### PR Template

When creating a PR, use this template:

```markdown
## Description
Brief description of what this PR does

## Type of Change
- [ ] Bug fix (non-breaking change)
- [ ] New feature (non-breaking change)
- [ ] Breaking change
- [ ] Documentation update

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots (if applicable)
[Add screenshots here]

## Checklist
- [ ] My code follows the project style guidelines
- [ ] I have performed a self-review
- [ ] I have commented my code where necessary
- [ ] I have updated the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests for my changes
- [ ] All tests pass locally

## Related Issues
Closes #(issue_number)
```

### Review Process

1. **Automated checks** - CI/CD runs tests and linting
2. **Code review** - At least one maintainer reviews the code
3. **Testing** - Manual testing if applicable
4. **Merge** - Squash and merge to maintain clean history

## Community

### Communication Channels

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - General discussions and questions
- **Email** - project-maintainers@example.com

### Recognition

Contributors who make significant contributions will be:
- Added to the CONTRIBUTORS.md file
- Mentioned in release notes
- Given credit in project documentation

## Development Tips

### Running in Demo Mode

```bash
flutter run -t lib/main_minimal.dart -d chrome --web-port 8080
```

### Useful Commands

```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Run tests with coverage
flutter test --coverage

# Generate documentation
dart doc .

# Check for outdated dependencies
flutter pub outdated
```

## Questions?

Feel free to open an issue with the `question` label or reach out to the maintainers directly.

---

Thank you for contributing to YatraLive! Together, we're making public transportation smarter and more accessible for everyone. 🚌✨
