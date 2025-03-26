const std = @import("std");
const net = std.net;
const json = std.json;
const Allocator = std.mem.Allocator;
const Thread = std.Thread;
const Mutex = std.Thread.Mutex;
const Condition = std.Thread.Condition;
const Plugin = @import("plugin").Plugin;
const types = @import("plugin").types;

pub const MessageType = enum {
    @"error",
    success,
    decompile,
    rename,
    list,
};

pub const Message = struct {
    type: MessageType,
    data: ?json.Value,

    pub fn init(type_: MessageType, data_: ?json.Value) Message {
        return Message{
            .type = type_,
            .data = data_,
        };
    }
};

pub const MCPServer = struct {
    allocator: Allocator,
    server: net.StreamServer,
    address: net.Address,
    analysis: ?*types.Program,

    pub fn init(allocator: Allocator, port: u16) !MCPServer {
        const address = try net.Address.parseIp("127.0.0.1", port);
        var server = net.StreamServer.init(.{});
        try server.listen(address);

        return MCPServer{
            .allocator = allocator,
            .server = server,
            .address = address,
            .analysis = null,
        };
    }

    pub fn deinit(self: *MCPServer) void {
        if (self.analysis) |analysis| {
            analysis.deinit();
        }
        self.server.close();
    }

    pub fn run(self: *MCPServer) !void {
        while (true) {
            const connection = try self.server.accept();
            defer connection.stream.close();

            try self.handleConnection(connection);
        }
    }

    fn handleConnection(self: *MCPServer, connection: net.StreamServer.Connection) !void {
        var buffer: [1024]u8 = undefined;
        while (true) {
            const bytes_read = try connection.stream.read(&buffer);
            if (bytes_read == 0) break;

            const message = try self.parseMessage(buffer[0..bytes_read]);
            const response = try self.handleMessage(message);
            try sendResponse(connection.stream, response);
        }
    }

    fn parseMessage(self: *MCPServer, data: []const u8) !Message {
        var parser = json.Parser.init(self.allocator, false);
        defer parser.deinit();

        var tree = try parser.parse(data);
        defer tree.deinit();

        const root = tree.root;
        const type_str = root.Object.get("type").?.String;
        const type_enum = std.meta.stringToEnum(MessageType, type_str) orelse return error.InvalidMessageType;

        return Message.init(type_enum, root.Object.get("data"));
    }

    fn handleMessage(self: *MCPServer, message: Message) !Message {
        return switch (message.type) {
            .decompile => self.handleDecompile(message),
            .rename => self.handleRename(message),
            .list => self.handleList(),
            else => Message.init(.@"error", json.Value{ .String = "Unsupported message type" }),
        };
    }

    fn handleDecompile(self: *MCPServer, message: Message) !Message {
        if (self.analysis == null) {
            return Message.init(.@"error", json.Value{ .String = "Analysis not initialized" });
        }

        const data = message.data.?.Object;
        const address = data.get("address").?.Integer;

        const decompiled = try self.analysis.?.decompileFunction(@intCast(address));
        defer self.allocator.free(decompiled);

        var response_data = json.ObjectMap.init(self.allocator);
        try response_data.put("decompiled", json.Value{ .String = decompiled });

        return Message.init(.success, json.Value{ .Object = response_data });
    }

    fn handleRename(self: *MCPServer, message: Message) !Message {
        if (self.analysis == null) {
            return Message.init(.@"error", json.Value{ .String = "Analysis not initialized" });
        }

        const data = message.data.?.Object;
        const address = data.get("address").?.Integer;
        const new_name = data.get("name").?.String;

        try self.analysis.?.renameFunction(@intCast(address), new_name);

        return Message.init(.success, null);
    }

    fn handleList(self: *MCPServer) !Message {
        if (self.analysis == null) {
            return Message.init(.@"error", json.Value{ .String = "Analysis not initialized" });
        }

        const functions = try self.analysis.?.listFunctions();
        defer self.allocator.free(functions);

        var response_data = json.ObjectMap.init(self.allocator);
        var functions_array = json.Array.init(self.allocator);

        for (functions) |function| {
            var function_obj = json.ObjectMap.init(self.allocator);
            try function_obj.put("name", json.Value{ .String = function.name });
            try function_obj.put("address", json.Value{ .Integer = @intCast(function.address) });
            try functions_array.append(json.Value{ .Object = function_obj });
        }

        try response_data.put("functions", json.Value{ .Array = functions_array });

        return Message.init(.success, json.Value{ .Object = response_data });
    }
};

fn sendResponse(stream: net.Stream, message: Message) !void {
    var buffer: [1024]u8 = undefined;
    var buffer_stream = std.io.fixedBufferStream(&buffer);
    var writer = buffer_stream.writer();

    try writer.print("{{\"type\":\"{s}\"", .{@tagName(message.type)});
    if (message.data) |data| {
        try writer.writeAll(",\"data\":");
        try json.stringify(data, .{}, writer);
    }
    try writer.writeAll("}\n");

    try stream.writeAll(buffer_stream.getWritten());
}

fn parseMessage(allocator: Allocator, data: []const u8) !Message {
    var parsed = try json.parseFromSlice(json.Value, allocator, data, .{});
    errdefer parsed.deinit();

    const type_str = parsed.value.Object.get("type").?.String;
    const message_type = std.meta.stringToEnum(MessageType, type_str) orelse return error.InvalidMessageType;

    const id = if (parsed.value.Object.get("id")) |id_value|
        try allocator.dupe(u8, id_value.String)
    else
        null;

    return Message{
        .type = message_type,
        .data = parsed.value,
        .id = id,
    };
}
