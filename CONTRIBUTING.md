# Contributing to Battery Limiter for Mac 🤝

Thank you for your interest in contributing to Battery Limiter! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites
- **macOS**: 10.10 (Yosemite) or later
- **Xcode**: 12.0 or later (latest recommended)
- **Swift**: 5.0 or later
- **Git**: Basic knowledge of Git workflows

### Development Environment Setup
1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/yourusername/battery-limiter.git
   cd battery-limiter
   ```
3. **Open** the project in Xcode:
   ```bash
   open BatteryLimiter.xcodeproj
   ```
4. **Build** the project (⌘+B) to ensure everything works

## 🏗️ Project Structure

```
BatteryLimiter/
├── BatteryLimiter.xcodeproj/     # Xcode project file
├── BatteryLimiter/               # Main app source
│   ├── BatteryLimiterApp.swift   # App delegate & menu bar setup
│   ├── BatteryMonitor.swift      # Battery monitoring logic
│   ├── ContentView.swift         # Main UI components
│   ├── Info.plist               # App configuration
│   └── Assets.xcassets/         # App icons & resources
├── README.md                     # Project documentation
├── LICENSE                       # MIT License
├── CONTRIBUTING.md               # This file
├── CHANGELOG.md                  # Version history
└── build.sh                      # Build script
```

## 🔧 Development Guidelines

### Code Style
- **Swift**: Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- **Formatting**: Use Xcode's built-in formatter (⌘+A, ⌘+I)
- **Naming**: Use descriptive names for variables, functions, and classes
- **Comments**: Add comments for complex logic or non-obvious code

### Architecture Principles
- **Separation of Concerns**: Keep UI, business logic, and data separate
- **ObservableObject**: Use SwiftUI's reactive patterns
- **Error Handling**: Implement proper error handling with meaningful messages
- **Memory Management**: Follow Swift's automatic memory management best practices

### Testing
- **Unit Tests**: Add tests for new functionality
- **UI Tests**: Test user interactions and workflows
- **Integration Tests**: Test battery monitoring functionality
- **Cross-Platform**: Test on different macOS versions when possible

## 🚀 Development Workflow

### 1. Create a Feature Branch
```bash
git checkout -b feature/amazing-feature
```

### 2. Make Your Changes
- Write clean, well-documented code
- Follow existing patterns in the codebase
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes
- Build the project (⌘+B)
- Run the app (⌘+R)
- Test the specific functionality you added
- Ensure no regressions in existing features

### 4. Commit Your Changes
```bash
git add .
git commit -m "feat: add amazing feature

- Added new battery monitoring capability
- Improved user interface responsiveness
- Added unit tests for new functionality"
```

### 5. Push and Create Pull Request
```bash
git push origin feature/amazing-feature
```
Then create a Pull Request on GitHub with:
- Clear description of changes
- Screenshots if UI changes
- Test results
- Any breaking changes

## 📝 Commit Message Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

### Examples:
```
feat: add battery health monitoring
fix: resolve menu bar icon visibility issue
docs: update installation instructions
style: format code according to guidelines
```

## 🐛 Bug Reports

When reporting bugs, please include:

1. **macOS Version**: e.g., macOS 13.0 (Ventura)
2. **App Version**: From the app's About dialog
3. **Steps to Reproduce**: Clear, step-by-step instructions
4. **Expected Behavior**: What should happen
5. **Actual Behavior**: What actually happens
6. **Screenshots**: If applicable
7. **Console Logs**: Any error messages or logs

## 💡 Feature Requests

For feature requests:

1. **Clear Description**: What you want and why
2. **Use Case**: How it would help users
3. **Mockups**: Visual examples if applicable
4. **Priority**: High/Medium/Low impact

## 🔍 Code Review Process

1. **Automated Checks**: Ensure CI passes
2. **Code Review**: At least one maintainer must approve
3. **Testing**: Verify functionality works as expected
4. **Documentation**: Update docs if needed
5. **Merge**: Once approved and tested

## 🧪 Testing Guidelines

### Unit Tests
- Test all public methods
- Mock external dependencies
- Test edge cases and error conditions
- Aim for >80% code coverage

### UI Tests
- Test user workflows
- Test accessibility features
- Test on different screen sizes
- Test in different macOS versions

### Manual Testing
- Test on different Mac models
- Test with different battery levels
- Test auto-start functionality
- Test notification system

## 📚 Documentation

### Code Documentation
- Document public APIs
- Add inline comments for complex logic
- Update README.md for user-facing changes
- Update CONTRIBUTING.md for developer changes

### User Documentation
- Clear installation instructions
- Usage examples
- Troubleshooting guides
- FAQ section

## 🚨 Security

- **No Sensitive Data**: Don't log or store sensitive information
- **Input Validation**: Validate all user inputs
- **Permission Handling**: Request only necessary permissions
- **Secure Storage**: Use Keychain for sensitive settings

## 🤝 Community Guidelines

- **Be Respectful**: Treat all contributors with respect
- **Be Helpful**: Help other contributors when possible
- **Be Patient**: Code reviews take time
- **Be Constructive**: Provide helpful feedback

## 📞 Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Pull Requests**: For code contributions
- **Wiki**: For detailed documentation

## 🎯 Current Priorities

- [ ] Improve battery monitoring accuracy
- [ ] Add battery health analytics
- [ ] Enhance user interface
- [ ] Add more customization options
- [ ] Improve auto-start reliability

## 🙏 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- GitHub contributors page
- Project documentation

---

**Thank you for contributing to Battery Limiter! Your help makes this project better for everyone.** 🚀
