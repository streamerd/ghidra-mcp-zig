# Include environment variables from .env file
include .env
export

# Zig compiler
ZIG=zig

# Build targets
.PHONY: all clean build-server build-plugin

all: build-server build-plugin

clean:
	@echo "Cleaning build artifacts..."
	rm -rf zig-cache
	rm -rf zig-out

build-server:
	@echo "Building MCP server..."
	$(ZIG) build install

build-plugin:
	@echo "Building Ghidra plugin..."
	$(ZIG) build install

run-server:
	@echo "Running MCP server..."
	$(ZIG) build run-server -Dghidra="$(GHIDRA_PATH)" -Djava_home="$(JAVA_HOME)"

help:
	@echo "Available targets:"
	@echo "  all          - Build everything (default)"
	@echo "  clean        - Remove build artifacts"
	@echo "  build-server - Build the MCP server"
	@echo "  build-plugin - Build the Ghidra plugin"
	@echo "  run-server   - Run the MCP server"
	@echo ""
	@echo "Environment variables (from .env):"
	@echo "  GHIDRA_PATH  - Path to Ghidra JAR file"
	@echo "  JAVA_HOME    - Path to Java installation" 