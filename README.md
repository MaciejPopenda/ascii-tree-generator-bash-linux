# ASCII Tree Generator (Shell Script)

A lightweight shell script that generates beautiful ASCII directory tree structures for your projects. Works on Linux and macOS without any dependencies - just pure bash!

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## ✨ Features

- 🌳 **Hierarchical .gitignore parsing** - Finds and applies all .gitignore files like git does
- 🎯 **Zero dependencies** - Pure bash, no Node.js or Python required
- 📁 **Flexible filtering** - Include/exclude files using regex patterns
- 📊 **Directory depth control** - Limit tree depth
- 🛠 **Debug mode** - See pattern matching details
- 💾 **Custom output** - Save anywhere with custom naming
- 🚀 **Dry run mode** - Preview before saving

## 📦 Installation

### Quick Install (Recommended)

```bash
# Download the script
curl -O https://raw.githubusercontent.com/MaciejPopenda/ascii-tree-generator-bash-linux/main/ascii-tree-generator.sh

# Make it executable
chmod +x ascii-tree-generator.sh

# Optionally, move to your PATH
sudo mv ascii-tree-generator.sh /usr/local/bin/ascii-tree-generator
```

### Manual Install

1. Clone this repository:
```bash
git clone https://github.com/MaciejPopenda/ascii-tree-generator-bash-linux.git
cd ascii-tree-generator-bash-linux
```

2. Make the script executable:
```bash
chmod +x ascii-tree-generator.sh
```

3. Run it:
```bash
./ascii-tree-generator.sh
```

## 🚀 Quick Start

Generate a tree for your current project:
```bash
./ascii-tree-generator.sh
```

This creates `project-ascii-tree.txt`:
```
my-project/
├── src/
│   ├── components/
│   │   ├── Header.js
│   │   └── Footer.js
│   └── index.js
├── package.json
└── README.md
```

## 📖 Usage Examples

### Basic Usage
```bash
# Generate tree with default settings
./ascii-tree-generator.sh

# Preview without creating file
./ascii-tree-generator.sh --dry-run

# Include all files (ignore .gitignore)
./ascii-tree-generator.sh --all
```

### Filtering Examples
```bash
# Only show JavaScript files
./ascii-tree-generator.sh --include-pattern '\.js$'

# Exclude tests
./ascii-tree-generator.sh --exclude-pattern 'test|spec'

# Show only source code
./ascii-tree-generator.sh --include-pattern 'src/'
```

### Advanced Examples
```bash
# Limit depth and save to docs/
./ascii-tree-generator.sh --max-depth 3 --output-path ./docs/

# Debug your patterns
./ascii-tree-generator.sh --debug --include-pattern '\.js$'

# Custom output with filters
./ascii-tree-generator.sh \
  --include-pattern '\.(md|txt)$' \
  --output-name "docs-structure.txt"
```

## ⚙️ Command Line Options

| Option | Description | Example |
|--------|-------------|---------|
| `--all` | Include all files (ignore .gitignore) | `--all` |
| `--except-dir` | Additional directories to ignore | `--except-dir "build,dist"` |
| `--except-file` | Additional files to ignore | `--except-file "*.log,*.tmp"` |
| `--output-name` | Custom output filename | `--output-name "tree.txt"` |
| `--output-path` | Custom output directory | `--output-path "./docs/"` |
| `--dry-run` | Preview without creating file | `--dry-run` |
| `--debug` | Show debug information | `--debug` |
| `--max-depth` | Maximum directory depth | `--max-depth 3` |
| `--include-pattern` | Regex to include files | `--include-pattern '\.js$'` |
| `--exclude-pattern` | Regex to exclude files/dirs | `--exclude-pattern 'test'` |
| `--help, -h` | Show help message | `--help` |

## 🖥️ Platform Support

- ✅ **Linux** - Works out of the box
- ✅ **macOS** - Works out of the box  
- ⚠️ **Windows** - Requires WSL, Git Bash, or Cygwin

### Windows Users

On Windows, you have these options:
1. **WSL (Windows Subsystem for Linux)** - Recommended
2. **Git Bash** - Comes with Git for Windows
3. **Cygwin** - Unix-like environment for Windows
4. **Use the Node.js version** - See [ascii-tree-generator](https://www.npmjs.com/package/ascii-tree-generator)

## 🔧 Git Integration

Add to `.git/hooks/post-commit`:
```bash
#!/bin/bash
cd "$(git rev-parse --show-toplevel)"
./ascii-tree-generator.sh
```

Make it executable:
```bash
chmod +x .git/hooks/post-commit
```

## 🎯 Pattern Matching

Uses grep Extended Regular Expressions (ERE):

```bash
# Single file type
--include-pattern '\.js$'

# Multiple file types
--include-pattern '\.(js|ts|json)$'

# Files containing 'component'
--include-pattern 'component'

# Exclude tests and build files
--exclude-pattern 'test|build|dist'
```

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 🐛 Issues

Found a bug? Please [open an issue](https://github.com/MaciejPopenda/ascii-tree-generator-bash-linux/issues)

## 🔗 Related Projects

- [ascii-tree-generator (Node.js version)](https://www.npmjs.com/package/ascii-tree-generator) - Original Node.js implementation

---

Made with ❤️ for developers who love simplicity