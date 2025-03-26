#ifndef MCP_BRIDGE_H
#define MCP_BRIDGE_H

#include <jni.h>

#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT void JNICALL Java_ghidra_plugin_mcp_MCPBridge_initializeServer
  (JNIEnv *, jobject, jint);

JNIEXPORT void JNICALL Java_ghidra_plugin_mcp_MCPBridge_startServer
  (JNIEnv *, jobject);

JNIEXPORT void JNICALL Java_ghidra_plugin_mcp_MCPBridge_stopServer
  (JNIEnv *, jobject);

JNIEXPORT void JNICALL Java_ghidra_plugin_mcp_MCPBridge_disposeServer
  (JNIEnv *, jobject);

JNIEXPORT jstring JNICALL Java_ghidra_plugin_mcp_MCPBridge_decompileFunction
  (JNIEnv *, jobject, jlong);

JNIEXPORT void JNICALL Java_ghidra_plugin_mcp_MCPBridge_renameFunction
  (JNIEnv *, jobject, jlong, jstring);

JNIEXPORT void JNICALL Java_ghidra_plugin_mcp_MCPBridge_renameData
  (JNIEnv *, jobject, jlong, jstring);

JNIEXPORT jobjectArray JNICALL Java_ghidra_plugin_mcp_MCPBridge_listFunctions
  (JNIEnv *, jobject);

JNIEXPORT jobjectArray JNICALL Java_ghidra_plugin_mcp_MCPBridge_listData
  (JNIEnv *, jobject);

JNIEXPORT jobjectArray JNICALL Java_ghidra_plugin_mcp_MCPBridge_listImports
  (JNIEnv *, jobject);

JNIEXPORT jobjectArray JNICALL Java_ghidra_plugin_mcp_MCPBridge_listExports
  (JNIEnv *, jobject);

#ifdef __cplusplus
}
#endif

#endif // MCP_BRIDGE_H 