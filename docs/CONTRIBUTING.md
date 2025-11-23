# Contributing Guide

Thank you for your interest in contributing to the Face Recognition app! This guide will help you get started.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Coding Standards](#coding-standards)
5. [Testing](#testing)
6. [Pull Request Process](#pull-request-process)

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Respect different viewpoints

## Getting Started

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/your-username/facerecognition.git
cd facerecognition

# Or clone the original repository
git clone https://github.com/alpharibbin/facerecognition.git
cd facerecognition
```

### 2. Setup Development Environment

Follow the [Setup Guide](SETUP.md) to configure your development environment.

### 3. Create Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

**Branch Naming**:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring

## Development Workflow

### 1. Make Changes

- Write clean, readable code
- Follow existing code style
- Add comments for complex logic
- Update documentation if needed

### 2. Test Your Changes

```bash
# Run tests
flutter test

# Run on device
flutter run

# Check for issues
flutter analyze
```

### 3. Commit Changes

```bash
git add .
git commit -m "Description of changes"
```

**Commit Message Format**:
```
type(scope): brief description

Detailed description if needed
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples**:
```
feat(detection): add confidence threshold setting
fix(registration): handle camera permission errors
docs(api): update DetectionService documentation
```

### 4. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Coding Standards

### Dart Style Guide

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.

### Code Formatting

```bash
# Format code
dart format .

# Or use IDE auto-format
```

### Naming Conventions

- **Classes**: PascalCase (`DetectionService`)
- **Variables**: camelCase (`faceEmbedding`)
- **Constants**: lowerCamelCase (`kBoxName`)
- **Files**: snake_case (`detection_service.dart`)

### Code Organization

```
lib/
├── face/           # UI pages
├── services/       # Business logic
├── models/         # Data models
├── utils/          # Utilities
└── main.dart       # Entry point
```

### Documentation

- Document public APIs
- Add comments for complex logic
- Update README for user-facing changes
- Update API docs for service changes

### Example

```dart
/// Service for managing face embeddings and matching.
///
/// This service handles synchronization between Firestore
/// and local Hive storage, and provides face matching functionality.
class DetectionService {
  /// Initialize the service and sync from Firestore.
  ///
  /// Opens Hive box and downloads all embeddings.
  Future<void> init() async {
    // Implementation
  }
}
```

## Testing

### Unit Tests

Create tests in `test/` directory:

```dart
// test/services/detection_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/detection_service.dart';

void main() {
  group('DetectionService', () {
    test('findBestMatch returns null for empty embeddings', () async {
      final service = DetectionService();
      final result = service.findBestMatch([]);
      expect(result, isNull);
    });
  });
}
```

### Widget Tests

```dart
// test/face/verification_page_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app/face/VerificationPage.dart';

void main() {
  testWidgets('VerificationPage displays email field', (tester) async {
    await tester.pumpWidget(MaterialApp(home: VerificationPage()));
    expect(find.byType(TextField), findsOneWidget);
  });
}
```

### Integration Tests

```dart
// integration_test/app_test.dart
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Complete registration flow', (tester) async {
    // Test implementation
  });
}
```

### Running Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/services/detection_service_test.dart

# With coverage
flutter test --coverage
```

## Pull Request Process

### Before Submitting

1. **Update Documentation**:
   - Update README if needed
   - Update API docs for service changes
   - Add comments for new code

2. **Run Checks**:
   ```bash
   flutter analyze
   flutter test
   flutter format .
   ```

3. **Test on Devices**:
   - Test on Android
   - Test on iOS (if available)
   - Test on different screen sizes

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] Unit tests added/updated
- [ ] Tested on Android
- [ ] Tested on iOS
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tests pass
- [ ] No breaking changes (or documented)
```

### Review Process

1. **Automated Checks**:
   - Code formatting
   - Linter checks
   - Tests must pass

2. **Code Review**:
   - At least one approval required
   - Address review comments
   - Update PR if needed

3. **Merge**:
   - Squash and merge (preferred)
   - Delete branch after merge

## Areas for Contribution

### High Priority

- [ ] Add unit tests for services
- [ ] Improve error handling
- [ ] Add face quality detection
- [ ] Optimize performance
- [ ] Add batch registration

### Medium Priority

- [ ] Add face groups/categories
- [ ] Improve UI/UX
- [ ] Add export/import functionality
- [ ] Add statistics dashboard
- [ ] Improve offline sync

### Low Priority

- [ ] Add dark mode
- [ ] Add multiple language support
- [ ] Add face clustering
- [ ] Add duplicate detection
- [ ] Improve documentation

## Questions?

- Open an issue on [GitHub](https://github.com/alpharibbin/facerecognition/issues) for bugs
- Start a discussion for features
- Contact maintainers for questions

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing! 🎉

