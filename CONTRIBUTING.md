# Contributing to EcoVolt Infrastructure

Thank you for your interest in contributing to the EcoVolt infrastructure project!

## 🚀 Quick Start

1. **Fork the repository**
2. **Clone your fork**: `git clone https://github.com/YOUR_USERNAME/ecovolt-infrastructure.git`
3. **Create a branch**: `git checkout -b feature/my-feature`
4. **Make changes**
5. **Test locally**: `make plan dev`
6. **Run tests**: `make test`
7. **Commit**: `git commit -am 'Add feature'`
8. **Push**: `git push origin feature/my-feature`
9. **Create Pull Request**

## 📋 Development Guidelines

### Code Standards

- **Format code**: Run `terraform fmt -recursive` before committing
- **Validate**: Run `terraform validate` to check syntax
- **Test**: Run `make test` to execute property-based tests
- **Security**: Run `make security-scan` to check for issues
- **Documentation**: Update relevant docs when making changes

### Commit Messages

Use conventional commits format:

```
feat: add new monitoring dashboard
fix: correct IAM policy for Lambda
docs: update deployment guide
test: add property test for encryption
chore: update Terraform version
```

### Pull Request Process

1. **Update documentation** if needed
2. **Add tests** for new functionality
3. **Ensure CI passes** (all checks must be green)
4. **Request review** from maintainers
5. **Address feedback** promptly
6. **Squash commits** before merge (if requested)

### Testing Requirements

- All new modules must have property-based tests
- Tests must pass before PR can be merged
- Add unit tests for complex logic
- Test in dev environment before staging/prod

## 🏗️ Module Development

### Creating a New Module

```bash
# Create module directory
mkdir -p modules/my-module

# Create required files
touch modules/my-module/{main.tf,variables.tf,outputs.tf,README.md}

# Add module to main.tf
# Add tests to test/properties/
```

### Module Structure

```
modules/my-module/
├── main.tf          # Main resources
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── locals.tf        # Local values (optional)
├── data.tf          # Data sources (optional)
└── README.md        # Module documentation
```

### Module Documentation

Each module README should include:
- Purpose and overview
- Usage example
- Input variables table
- Output values table
- Dependencies

## 🧪 Testing

### Run All Tests

```bash
make test
```

### Run Specific Tests

```bash
# Unit tests only
make test-unit

# Property tests only
make test-properties

# Specific module
cd test && go test -v -run TestPropertyNetworking
```

### Writing Tests

See [test/README.md](test/README.md) for testing guidelines.

## 🔐 Security

### Security Requirements

- Never commit secrets or credentials
- Use Secrets Manager for sensitive data
- Follow least privilege principle for IAM
- Enable encryption for all data stores
- Use private subnets for databases
- Enable MFA for production access

### Security Scanning

```bash
# Run tfsec
tfsec .

# Run Checkov
checkov -d .

# Both
make security-scan
```

## 📝 Documentation

### Update Documentation When:

- Adding new modules
- Changing architecture
- Modifying deployment process
- Adding new features
- Fixing bugs that affect usage

### Documentation Standards

- Use clear, concise language
- Include code examples
- Add diagrams where helpful
- Keep docs up to date with code
- Link related documents

## 🐛 Reporting Issues

### Before Reporting

1. Check [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Search existing issues
3. Try with latest version

### Issue Template

```markdown
**Description**
Clear description of the issue

**Steps to Reproduce**
1. Step one
2. Step two
3. Step three

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- Terraform version:
- AWS region:
- Environment: dev/staging/prod

**Logs**
Relevant error messages or logs
```

## 🎯 Areas for Contribution

### High Priority

- Performance optimization
- Cost reduction strategies
- Additional security controls
- Improved monitoring
- Documentation improvements

### Medium Priority

- Additional modules (SageMaker, QuickSight)
- Enhanced testing coverage
- Automation scripts
- Example applications

### Low Priority

- UI improvements for dashboards
- Additional integrations
- Performance benchmarks

## 💬 Communication

- **Questions**: Use GitHub Discussions
- **Bugs**: Use GitHub Issues
- **Features**: Use GitHub Issues with `enhancement` label
- **Security**: Email thekoudwiz+ecovolt@gmail.com (do not use public issues)

## ✅ Code Review Process

### What We Look For

- Code quality and readability
- Test coverage
- Documentation updates
- Security considerations
- Performance impact
- Cost implications

### Review Timeline

- Initial review: Within 2 business days
- Follow-up reviews: Within 1 business day
- Merge: After approval from 2 maintainers

## 🏆 Recognition

Contributors will be:
- Listed in release notes
- Mentioned in documentation
- Added to CONTRIBUTORS.md (if significant contribution)

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Thank You!

Your contributions help make EcoVolt better for everyone. We appreciate your time and effort!

---

**Questions?** Open a [GitHub Discussion](https://github.com/thekloudwiz-org/ecovolt-infrastructure/discussions)
