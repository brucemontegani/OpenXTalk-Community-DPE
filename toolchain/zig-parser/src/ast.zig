const std = @import("std");

pub const HandlerType = enum {
    message,
    function,
};

pub const Handler = struct {
    handler_type: HandlerType,
    name: []const u8,
    params: []const []const u8,
    body_start: usize,
    body_end: usize,

    pub fn format(
        self: Handler,
        writer: anytype,
    ) !void {
        const type_str = switch (self.handler_type) {
            .message => "message",
            .function => "function",
        };
        try writer.print("handler: {s} ({s}) params: [", .{ self.name, type_str });
        for (self.params, 0..) |p, i| {
            if (i > 0) try writer.writeAll(", ");
            try writer.writeAll(p);
        }
        try writer.print("] body: tokens {d}..{d}", .{ self.body_start, self.body_end });
    }
};

pub const Script = struct {
    handlers: []const Handler,

    pub fn deinit(self: Script, allocator: std.mem.Allocator) void {
        for (self.handlers) |h| {
            allocator.free(h.params);
        }
        allocator.free(self.handlers);
    }
};
