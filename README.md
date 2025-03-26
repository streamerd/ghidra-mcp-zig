# Ghidra MCP Zig Plugin

A Ghidra plugin that provides a bridge between Ghidra and a Zig-based MCP server for enhanced program analysis capabilities.

## Features

- JNI-based communication between Ghidra and Zig
- Function decompilation and renaming
- Data symbol management
- Import/Export listing
- MCP server integration
- Comprehensive test suite
- Modern build system with Zig
- Efficient memory management
- Type-safe JNI bridge implementation
- Go client library for easy integration

## Prerequisites

- [Zig](https://ziglang.org/) (version 0.13.0 or later)
- [Ghidra](https://ghidra-sre.org/) (version 11.3.1 or later)
- Java Development Kit (JDK) 17 or later
- [Go](https://golang.org/) (version 1.22.4 or later)
- [Gradle](https://gradle.org/) (version 8.13 or later)
- Make

## Project Structure

```
ghidra-mcp-zig/
├── src/
│   ├── plugin/
│   │   ├── jni/
│   │   │   └── bridge.zig    # JNI interface implementation
│   │   ├── analysis.zig      # Program analysis logic
│   │   └── plugin.zig        # Plugin initialization
│   └── server/
│       └── main.zig          # MCP server implementation
├── java/                     # Ghidra plugin Java code
│   ├── build.gradle         # Gradle build configuration
│   ├── gradlew             # Gradle wrapper script
│   └── src/                # Java source files
├── pkg/
│   └── mcp/
│       └── client/         # Go MCP client library
│           ├── client.go   # Client implementation
│           └── client_test.go # Client tests
├── build.zig               # Build configuration
├── build.zig.zon          # Dependencies configuration
├── go.mod                 # Go module definition
└── Makefile              # Build automation
```

## Dependencies

- [zig-jni](https://github.com/SuperIceCN/zig-jni) (v0.0.9) - JNI bindings for Zig


## Building

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ghidra-mcp-zig.git
   cd ghidra-mcp-zig
   ```

2. Create a `.env` file with the following variables:
   ```
   GHIDRA_PATH=/path/to/ghidra_11.3.1_PUBLIC/Ghidra/Features/Base/lib/Base.jar
   JAVA_HOME=/path/to/your/jdk
   ```

3. Build the project:
   ```bash
   # Build everything
   make all

   # Or build specific components
   make build-server    # Build the MCP server
   make build-plugin   # Build the Ghidra plugin
   ```

4. Run the server:
   ```bash
   make run-server
   ```

### Build Targets

| Target | Description | Example Usage |
|--------|-------------|---------------|
| `all` | Build all components | `make all` |
| `build-server` | Build MCP server | `make build-server` |
| `build-plugin` | Build Ghidra plugin | `make build-plugin` |
| `clean` | Clean all artifacts | `make clean` |
| `clean-server` | Clean server artifacts | `make clean-server` |
| `clean-plugin` | Clean plugin artifacts | `make clean-plugin` |

### Run Targets

| Target | Description | Example Usage |
|--------|-------------|---------------|
| `run-server` | Start MCP server | `make run-server` |
| `run-plugin` | Start Ghidra plugin | `make run-plugin` |

### Test Targets

| Target | Description | Example Usage |
|--------|-------------|---------------|
| `test` | Run all tests | `make test` |
| `test-server` | Run server tests | `make test-server` |
| `test-plugin` | Run plugin tests | `make test-plugin` |

For a complete list of available targets, run:
```bash
make help
```

## Installation

1. Build the plugin:
   ```bash
   make build-plugin
   ```

2. Copy the built plugin to your Ghidra plugins directory:
   ```bash
   cp zig-out/lib/libghidra-mcp-zig.dylib /path/to/ghidra/Extensions/Ghidra/ghidra-mcp-zig/
   ```

3. Restart Ghidra

## Usage

1. Start Ghidra and open a program for analysis
2. The MCP plugin will be available in the Ghidra plugin manager
3. Use the plugin's features through the Ghidra interface

### Available MCP Commands

| Command | Description | Parameters |
|---------|-------------|------------|
| `decompile` | Decompile a function | `address: u64` |
| `rename_function` | Rename a function | `address: u64, new_name: string` |
| `rename_data` | Rename a data object | `address: u64, new_name: string` |
| `list_functions` | List all functions | None |
| `list_data` | List all data objects | None |
| `list_imports` | List all imports | None |
| `list_exports` | List all exports | None |

### Error Handling

The implementation includes comprehensive error handling with specific error types:

| Error Type | Description |
|------------|-------------|
| `ConnectionError` | Connection-related errors |
| `MessageError` | Message handling errors |
| `ResponseError` | Response parsing errors |
| `InvalidAddress` | Invalid memory address |
| `InvalidFunction` | Invalid function reference |
| `InvalidData` | Invalid data reference |
| `DecompilationFailed` | Function decompilation failed |
| `RenameFailed` | Rename operation failed |
| `OutOfMemory` | Memory allocation failed |
| `InvalidProgram` | Invalid program state |
| `JNIError` | JNI bridge errors |

## Development

### Adding New Features

1. Update the JNI interface in `src/plugin/jni/bridge.zig`
2. Implement the corresponding functionality in `src/plugin/analysis.zig`
3. Update the server implementation in `src/server/main.zig` if needed
4. Rebuild and test

### Debugging

- Use `make clean` to remove build artifacts
- Check the Ghidra log for plugin-related messages
- The server logs will be available in the console when running with `make run-server`

### JNI Bridge Implementation

The JNI bridge provides a type-safe interface between Zig and Java:

- Memory management with proper allocation/deallocation
- JNI reference management with `DeleteLocalRef`
- Error handling with null checks
- Type conversion between Zig and Java types
- Array creation and element setting
- Object creation and field setting

#### Key Features

1. **Memory Safety**
   - Automatic cleanup of JNI references
   - Proper string handling with UTF-8 conversion
   - Safe memory allocation and deallocation

2. **Type Safety**
   - Strong typing for all JNI operations
   - Compile-time type checking
   - Safe type conversions

3. **Error Handling**
   - Comprehensive error types
   - Null checks for all JNI operations
   - Proper cleanup on error

4. **Object Management**
   - Safe object creation and destruction
   - Field access with type checking
   - Array handling with bounds checking

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 