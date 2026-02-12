const std = @import("std");

pub const HandlerType = enum {
    message,
    function,
};

pub const ExprSpan = struct {
    start: usize,
    end: usize,
};

pub const PutVariant = enum {
    into,
    after,
    before,
};

pub const RepeatCounter = struct {
    var_name: []const u8,
    start: ExprSpan,
    end: ExprSpan,
};

pub const Statement = union(enum) {
    put: PutStatement,
    return_stmt: ReturnStatement,
    if_stmt: IfStatement,
    repeat_stmt: RepeatStatement,
    command_call: CommandCall,
};

pub const PutStatement = struct {
    source: ExprSpan,
    variant: PutVariant,
    target: ExprSpan,
};

pub const ReturnStatement = struct {
    value: ?ExprSpan,
};

pub const IfStatement = struct {
    condition: ExprSpan,
    then_body: []const Statement,
    else_body: []const Statement,
    single_line: bool,
};

pub const RepeatStatement = struct {
    counter: ?RepeatCounter,
    body: []const Statement,
};

pub const CommandCall = struct {
    name: []const u8,
    args: ?ExprSpan,
};

pub fn deinitStatements(stmts: []const Statement, allocator: std.mem.Allocator) void {
    for (stmts) |stmt| {
        switch (stmt) {
            .if_stmt => |ifs| {
                deinitStatements(ifs.then_body, allocator);
                allocator.free(ifs.then_body);
                deinitStatements(ifs.else_body, allocator);
                allocator.free(ifs.else_body);
            },
            .repeat_stmt => |rep| {
                deinitStatements(rep.body, allocator);
                allocator.free(rep.body);
            },
            .put, .return_stmt, .command_call => {},
        }
    }
}

pub const Handler = struct {
    handler_type: HandlerType,
    name: []const u8,
    params: []const []const u8,
    body: []const Statement,

    pub fn deinit(self: Handler, allocator: std.mem.Allocator) void {
        deinitStatements(self.body, allocator);
        allocator.free(self.body);
        allocator.free(self.params);
    }
};

pub const Script = struct {
    handlers: []const Handler,

    pub fn deinit(self: Script, allocator: std.mem.Allocator) void {
        for (self.handlers) |h| {
            h.deinit(allocator);
        }
        allocator.free(self.handlers);
    }
};
