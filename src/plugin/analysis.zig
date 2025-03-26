const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const jni = @import("jni/bridge.zig");
const types = @import("types.zig");

pub const AnalysisError = error{
    InvalidAddress,
    InvalidFunction,
    InvalidData,
    DecompilationFailed,
    RenameFailed,
    OutOfMemory,
    InvalidProgram,
    JNIError,
};

pub const Analysis = struct {
    allocator: Allocator,
    program: ?*types.Program,
    env: ?*jni.JNIEnv,

    pub fn init(allocator: Allocator) Analysis {
        return Analysis{
            .allocator = allocator,
            .program = null,
            .env = null,
        };
    }

    pub fn deinit(self: *Analysis) void {
        if (self.program) |program| {
            program.deinit();
        }
    }

    pub fn setJNIEnv(self: *Analysis, env: *jni.JNIEnv) void {
        self.env = env;
    }

    pub fn decompileFunction(self: *Analysis, address: u64) AnalysisError![]const u8 {
        if (self.program == null) return error.InvalidProgram;
        if (self.env == null) return error.JNIError;

        const env = self.env.?;
        const result = jni.Java_ghidra_plugin_mcp_MCPBridge_decompileFunction(env, null, @intCast(address));
        if (result == null) return error.DecompilationFailed;

        const len = env.*.GetStringUTFLength.?(env, result);
        const chars = env.*.GetStringUTFChars.?(env, result, null);
        if (chars == null) return error.DecompilationFailed;

        const decompiled = self.allocator.alloc(u8, @intCast(len));
        errdefer self.allocator.free(decompiled);

        std.mem.copy(u8, decompiled, chars[0..@intCast(len)]);
        env.*.ReleaseStringUTFChars.?(env, result, chars);

        return decompiled;
    }

    pub fn renameFunction(self: *Analysis, address: u64, new_name: []const u8) AnalysisError!void {
        if (self.program == null) return error.InvalidProgram;
        if (self.env == null) return error.JNIError;

        const env = self.env.?;
        const new_name_jstring = env.*.NewStringUTF.?(env, new_name.ptr);
        if (new_name_jstring == null) return error.RenameFailed;

        jni.Java_ghidra_plugin_mcp_MCPBridge_renameFunction(env, null, @intCast(address), new_name_jstring);
        env.*.DeleteLocalRef.?(env, new_name_jstring);
    }

    pub fn renameData(self: *Analysis, address: u64, new_name: []const u8) AnalysisError!void {
        if (self.program == null) return error.InvalidProgram;
        if (self.env == null) return error.JNIError;

        const env = self.env.?;
        const new_name_jstring = env.*.NewStringUTF.?(env, new_name.ptr);
        if (new_name_jstring == null) return error.RenameFailed;

        jni.Java_ghidra_plugin_mcp_MCPBridge_renameData(env, null, @intCast(address), new_name_jstring);
        env.*.DeleteLocalRef.?(env, new_name_jstring);
    }

    pub fn listFunctions(self: *Analysis) AnalysisError![]types.Function {
        if (self.program == null) return error.InvalidProgram;
        if (self.env == null) return error.JNIError;

        const env = self.env.?;
        const functions_array = jni.Java_ghidra_plugin_mcp_MCPBridge_listFunctions(env, null);
        if (functions_array == null) return error.OutOfMemory;

        const len = env.*.GetArrayLength.?(env, functions_array);
        var functions = ArrayList(types.Function).init(self.allocator);
        errdefer functions.deinit();

        for (0..@intCast(len)) |i| {
            const function_obj = env.*.GetObjectArrayElement.?(env, functions_array, @intCast(i));
            if (function_obj == null) continue;

            const name_jstring = env.*.GetObjectField.?(env, function_obj, jni.function_name_field_id);
            const address_jlong = env.*.GetLongField.?(env, function_obj, jni.function_address_field_id);

            if (name_jstring != null) {
                const name_len = env.*.GetStringUTFLength.?(env, name_jstring);
                const name_chars = env.*.GetStringUTFChars.?(env, name_jstring, null);
                if (name_chars != null) {
                    const name = self.allocator.alloc(u8, @intCast(name_len));
                    errdefer self.allocator.free(name);
                    std.mem.copy(u8, name, name_chars[0..@intCast(name_len)]);
                    env.*.ReleaseStringUTFChars.?(env, name_jstring, name_chars);

                    try functions.append(types.Function{
                        .name = name,
                        .address = @intCast(address_jlong),
                    });
                }
                env.*.ReleaseStringUTFChars.?(env, name_jstring, null);
            }
            env.*.DeleteLocalRef.?(env, function_obj);
        }

        env.*.DeleteLocalRef.?(env, functions_array);
        return functions.toOwnedSlice();
    }

    pub fn listData(self: *Analysis) AnalysisError![]types.Data {
        if (self.program == null) return error.InvalidProgram;
        if (self.env == null) return error.JNIError;

        const env = self.env.?;
        const data_array = jni.Java_ghidra_plugin_mcp_MCPBridge_listData(env, null);
        if (data_array == null) return error.OutOfMemory;

        const len = env.*.GetArrayLength.?(env, data_array);
        var data = ArrayList(types.Data).init(self.allocator);
        errdefer data.deinit();

        for (0..@intCast(len)) |i| {
            const data_obj = env.*.GetObjectArrayElement.?(env, data_array, @intCast(i));
            if (data_obj == null) continue;

            const name = getStringField(env, data_obj, "name") orelse continue;
            const address = getLongField(env, data_obj, "address");
            const size = getLongField(env, data_obj, "size");
            const data_type = getStringField(env, data_obj, "type") orelse continue;

            try data.append(types.Data{
                .name = name,
                .address = @intCast(address),
                .size = @intCast(size),
                .type = data_type,
            });

            env.*.DeleteLocalRef.?(env, data_obj);
        }

        env.*.DeleteLocalRef.?(env, data_array);
        return data.toOwnedSlice();
    }

    pub fn listImports(self: *Analysis) AnalysisError![]types.Import {
        if (self.program == null) return error.InvalidProgram;
        if (self.env == null) return error.JNIError;

        const env = self.env.?;
        const imports_array = jni.Java_ghidra_plugin_mcp_MCPBridge_listImports(env, null);
        if (imports_array == null) return error.OutOfMemory;

        const len = env.*.GetArrayLength.?(env, imports_array);
        var imports = ArrayList(types.Import).init(self.allocator);
        errdefer imports.deinit();

        for (0..@intCast(len)) |i| {
            const import_obj = env.*.GetObjectArrayElement.?(env, imports_array, @intCast(i));
            if (import_obj == null) continue;

            const name = getStringField(env, import_obj, "name") orelse continue;
            const address = getLongField(env, import_obj, "address");
            const library = getStringField(env, import_obj, "library") orelse continue;

            try imports.append(types.Import{
                .name = name,
                .address = @intCast(address),
                .library = library,
            });

            env.*.DeleteLocalRef.?(env, import_obj);
        }

        env.*.DeleteLocalRef.?(env, imports_array);
        return imports.toOwnedSlice();
    }

    pub fn listExports(self: *Analysis) AnalysisError![]types.Export {
        if (self.program == null) return error.InvalidProgram;
        if (self.env == null) return error.JNIError;

        const env = self.env.?;
        const exports_array = jni.Java_ghidra_plugin_mcp_MCPBridge_listExports(env, null);
        if (exports_array == null) return error.OutOfMemory;

        const len = env.*.GetArrayLength.?(env, exports_array);
        var exports = ArrayList(types.Export).init(self.allocator);
        errdefer exports.deinit();

        for (0..@intCast(len)) |i| {
            const export_obj = env.*.GetObjectArrayElement.?(env, exports_array, @intCast(i));
            if (export_obj == null) continue;

            const name = getStringField(env, export_obj, "name") orelse continue;
            const address = getLongField(env, export_obj, "address");
            const export_type = getStringField(env, export_obj, "type") orelse continue;

            try exports.append(types.Export{
                .name = name,
                .address = @intCast(address),
                .type = export_type,
            });

            env.*.DeleteLocalRef.?(env, export_obj);
        }

        env.*.DeleteLocalRef.?(env, exports_array);
        return exports.toOwnedSlice();
    }
};

fn getStringField(env: *jni.JNIEnv, obj: jni.jobject, field_name: []const u8) ?[]const u8 {
    const class = env.*.GetObjectClass.?(env, obj);
    if (class == null) return null;
    defer env.*.DeleteLocalRef.?(env, class);

    const field_id = env.*.GetFieldID.?(env, class, field_name.ptr, "Ljava/lang/String;");
    if (field_id == null) return null;

    const jstring = env.*.GetObjectField.?(env, obj, field_id);
    if (jstring == null) return null;
    defer env.*.DeleteLocalRef.?(env, jstring);

    const len = env.*.GetStringUTFLength.?(env, jstring);
    const chars = env.*.GetStringUTFChars.?(env, jstring, null);
    if (chars == null) return null;

    const result = std.heap.c_allocator.alloc(u8, @intCast(len));
    std.mem.copy(u8, result, chars[0..@intCast(len)]);
    env.*.ReleaseStringUTFChars.?(env, jstring, chars);

    return result;
}

fn getLongField(env: *jni.JNIEnv, obj: jni.jobject, field_name: []const u8) i64 {
    const class = env.*.GetObjectClass.?(env, obj);
    if (class == null) return 0;
    defer env.*.DeleteLocalRef.?(env, class);

    const field_id = env.*.GetFieldID.?(env, class, field_name.ptr, "J");
    if (field_id == null) return 0;

    return env.*.GetLongField.?(env, obj, field_id);
}
