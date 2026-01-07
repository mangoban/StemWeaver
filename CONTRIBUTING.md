# Contributing to StemWeaver

Thank you for your interest in contributing to StemWeaver! This document provides guidelines and instructions for contributing to the project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Bug Reports](#bug-reports)
- [Feature Requests](#feature-requests)
- [License](#license)

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainer.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Set up the development environment
4. Create a branch for your contribution

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported
2. Use the bug report template
3. Include detailed steps to reproduce
4. Provide system information (OS, Python version, etc.)

### Suggesting Features

1. Check if the feature has already been suggested
2. Use the feature request template
3. Explain the use case and benefits
4. Consider implementation details

### Code Contributions

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test thoroughly
5. Commit with clear message: `git commit -m "Add amazing feature"`
6. Push to your fork: `git push origin feature/amazing-feature`
7. Open a Pull Request

## Development Setup

### Prerequisites

- Python 3.9+
- Git
- Virtual environment tool (venv)

### Installation

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/StemWeaver.git
cd StemWeaver

# Or clone the main repository
git clone https://github.com/mangoban/StemWeaver.git
cd StemWeaver

# Create virtual environment
python -m venv myenv
source myenv/bin/activate  # On Windows: myenv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run development version
python gui_data/gui_modern_extractor.py
```

### Project Structure

```
StemWeaver/
├── gui_data/          # GUI source code
├── lib_v5/           # AI model libraries
├── models/           # Pre-trained models
├── packaging/        # Build scripts
├── docs/             # Documentation
├── dev/              # Development tools
└── requirements.txt  # Python dependencies
```

## Pull Request Process

1. **Fork and Branch**: Fork the repo and create a feature branch
2. **Code Style**: Follow existing code style and conventions
3. **Tests**: Add tests for new functionality
4. **Documentation**: Update README and docs if needed
5. **Commit Messages**: Use clear, descriptive commit messages
6. **PR Description**: Explain what changes were made and why

### PR Checklist

- [ ] Code follows project style
- [ ] Tests pass locally
- [ ] Documentation updated
- [ ] Changelog updated (if applicable)
- [ ] PR description is clear

## Bug Reports

Use the bug report template with:

- **Title**: Clear, descriptive title
- **Description**: What happened vs what you expected
- **Steps to Reproduce**: Minimal steps
- **Environment**: OS, Python version, dependencies
- **Screenshots**: If applicable
- **Logs**: Error messages and logs

## Feature Requests

Use the feature request template with:

- **Title**: Clear, descriptive title
- **Problem**: What problem does this solve?
- **Solution**: Proposed solution
- **Alternatives**: Other solutions considered
- **Additional Context**: Any other relevant info

## Development Guidelines

### Code Style

- Use descriptive variable names
- Add docstrings to functions
- Keep functions focused and small
- Comment complex logic
- Follow PEP 8 style guide

### Testing

- Test on multiple Python versions
- Test on different Linux distributions
- Test with and without GPU
- Test with various audio formats

### Documentation

- Update README for user-facing changes
- Update docs/ for technical changes
- Add inline comments for complex logic
- Keep commit messages clear

## License

By contributing, you agree that your contributions will be licensed under the **Creative Commons Attribution 4.0 International (CC BY 4.0)** license.

This means:
- ✅ Your contributions will be credited to you
- ✅ bendeb creations retains overall project ownership
- ✅ All users must give credit to bendeb creations
- ✅ Commercial use is allowed with proper attribution
- ✅ You can support development at: https://buymeacoffee.com/mangoban

## Questions?

Feel free to contact the maintainer or open an issue for questions.

---

**Thank you for contributing to StemWeaver!** 🎵
