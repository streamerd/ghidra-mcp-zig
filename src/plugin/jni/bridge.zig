const std = @import("std");
const jni = @import("jni");
const Analysis = @import("../analysis.zig").Analysis;

pub const MCPBridge = struct {
    env: *jni.JNIEnv,
    this: jni.jobject,

    pub fn init(env: *jni.JNIEnv, this: jni.jobject) MCPBridge {
        return MCPBridge{
            .env = env,
            .this = this,
        };
    }
};

pub fn Java_ghidra_mcp_MCPPlugin_init(env: *jni.cEnv, _: jni.jclass) callconv(.C) jni.jint {
    var analysis = Analysis.init();
    analysis.setJNIEnv(env);
    analysis.start();
    return jni.JNI_OK;
}

pub fn Java_ghidra_mcp_MCPPlugin_deinit(env: *jni.cEnv, _: jni.jclass) callconv(.C) void {
    _ = env;
}

pub fn Java_ghidra_plugin_mcp_MCPBridge_decompileFunction(env: *jni.cEnv, _: jni.jclass, _: jni.jstring, newName: jni.jstring) callconv(.C) jni.jstring {
    const isCopy: bool = false;
    const chars = env.GetStringUTFChars.?(env, newName, &isCopy);
    _ = chars;
    return null;
}

pub fn Java_ghidra_plugin_mcp_MCPBridge_renameFunction(env: *jni.cEnv, _: jni.jclass, oldName: jni.jstring, newName: jni.jstring) callconv(.C) jni.jstring {
    _ = env;
    _ = oldName;
    _ = newName;
    return null;
}

pub fn Java_ghidra_plugin_mcp_MCPBridge_renameData(env: *jni.cEnv, _: jni.jclass, oldName: jni.jstring, newName: jni.jstring) callconv(.C) jni.jstring {
    _ = env;
    _ = oldName;
    _ = newName;
    return null;
}

pub fn Java_ghidra_plugin_mcp_MCPBridge_listFunctions(env: *jni.cEnv, _: jni.jclass, name: jni.jstring) callconv(.C) jni.jobjectArray {
    const isCopy: bool = false;
    const chars = env.GetStringUTFChars.?(env, name, &isCopy);
    _ = chars;
    return null;
}

pub fn Java_ghidra_plugin_mcp_MCPBridge_listData(env: *jni.cEnv, _: jni.jclass) callconv(.C) jni.jobjectArray {
    _ = env;
    return null;
}

pub fn Java_ghidra_plugin_mcp_MCPBridge_listImports(env: *jni.cEnv, _: jni.jclass) callconv(.C) jni.jobjectArray {
    _ = env;
    return null;
}

pub fn Java_ghidra_plugin_mcp_MCPBridge_listExports(env: *jni.cEnv, _: jni.jclass) callconv(.C) jni.jobjectArray {
    _ = env;
    return null;
}

pub fn Java_ghidra_plugin_mcp_MCPBridge_startServer(env: *jni.cEnv, _: jni.jclass) callconv(.C) jni.jint {
    _ = env;
    return 0;
}

pub fn Java_ghidra_plugin_mcp_MCPBridge_stopServer(env: *jni.cEnv, _: jni.jclass) callconv(.C) void {
    _ = env;
}
