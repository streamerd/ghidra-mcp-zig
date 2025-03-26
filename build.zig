const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add JNI dependency
    const jni_dep = b.dependency("JNI", .{}).module("JNI");

    // Create plugin module
    const plugin_module = b.addModule("plugin", .{
        .root_source_file = .{ .cwd_relative = "src/plugin/plugin.zig" },
    });
    plugin_module.addImport("jni", jni_dep);

    // Create plugin library
    const plugin = b.addSharedLibrary(.{
        .name = "ghidra-mcp-zig",
        .root_source_file = .{ .cwd_relative = "src/plugin/plugin.zig" },
        .target = target,
        .optimize = optimize,
    });
    plugin.root_module.addImport("jni", jni_dep);
    plugin.linkLibC();

    // Create server executable
    const server = b.addExecutable(.{
        .name = "mcp-server",
        .root_source_file = .{ .cwd_relative = "src/server/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    server.root_module.addImport("plugin", plugin_module);
    server.root_module.addImport("jni", jni_dep);
    server.linkLibC();

    // Install artifacts
    b.installArtifact(plugin);
    b.installArtifact(server);

    // Create run command
    const run_cmd = b.addRunArtifact(server);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the server");
    run_step.dependOn(&run_cmd.step);
}
