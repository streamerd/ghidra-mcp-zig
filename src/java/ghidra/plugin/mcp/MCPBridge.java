package ghidra.plugin.mcp;

public class MCPBridge {
    static {
        System.loadLibrary("ghidra-mcp-plugin");
    }

    // Native method declarations
    public native void initializeServer(int port);
    public native void startServer();
    public native void stopServer();
    public native void disposeServer();

    // Program analysis methods
    public native String decompileFunction(long address);
    public native void renameFunction(long address, String newName);
    public native void renameData(long address, String newName);
    public native String[] listFunctions();
    public native String[] listData();
    public native String[] listImports();
    public native String[] listExports();
} 