const std = @import("std");
const token_mod = @import("token.zig");
const ast_mod = @import("ast.zig");
const Token = token_mod.Token;
const Tag = token_mod.Tag;
const Handler = ast_mod.Handler;
const HandlerType = ast_mod.HandlerType;
const Script = ast_mod.Script;

pub const ParseError = error{
    UnexpectedToken,
    UnmatchedEnd,
    UnexpectedEof,
    OutOfMemory,
};

pub const Parser = struct {
    tokens: []const Token,
    source: []const u8,
    index: usize,
    allocator: std.mem.Allocator,

    pub fn init(tokens: []const Token, source: []const u8, allocator: std.mem.Allocator) Parser {
        return .{
            .tokens = tokens,
            .source = source,
            .index = 0,
            .allocator = allocator,
        };
    }

    pub fn parse(self: *Parser) ParseError!Script {
        var handlers: std.ArrayList(Handler) = .empty;
        errdefer {
            for (handlers.items) |h| {
                self.allocator.free(h.params);
            }
            handlers.deinit(self.allocator);
        }

        while (true) {
            self.skipWhitespace();
            const tag = self.peek();
            if (tag == .ST_EOF) break;
            if (tag == .KW_ON or tag == .KW_FUNCTION) {
                const handler = try self.parseHandler();
                handlers.append(self.allocator, handler) catch return error.OutOfMemory;
            } else {
                // Skip non-handler tokens at top level
                _ = self.advance();
            }
        }

        return .{
            .handlers = handlers.toOwnedSlice(self.allocator) catch return error.OutOfMemory,
        };
    }

    fn parseHandler(self: *Parser) ParseError!Handler {
        // Consume 'on' or 'function'
        const handler_tok = self.advance();
        const handler_type: HandlerType = switch (handler_tok.tag) {
            .KW_ON => .message,
            .KW_FUNCTION => .function,
            else => return error.UnexpectedToken,
        };

        self.skipSpaces();

        // Expect handler name (identifier)
        const name_tok = try self.expect(.ST_ID);
        const name = self.source[name_tok.loc.start..name_tok.loc.end];

        // Parse parameter list until EOL or EOF
        var params: std.ArrayList([]const u8) = .empty;
        errdefer params.deinit(self.allocator);

        self.skipSpaces();

        // Parse params: comma-separated identifiers until EOL/EOF
        while (self.peek() != .ST_EOL and self.peek() != .ST_EOF) {
            const ptag = self.peek();
            if (ptag == .ST_ID) {
                const param_tok = self.advance();
                params.append(self.allocator, self.source[param_tok.loc.start..param_tok.loc.end]) catch return error.OutOfMemory;
                self.skipSpaces();
                // Skip optional comma
                if (self.peek() == .ST_SEP) {
                    _ = self.advance();
                    self.skipSpaces();
                }
            } else {
                // Skip unexpected token in param list
                _ = self.advance();
            }
        }

        // Skip the EOL
        if (self.peek() == .ST_EOL) {
            _ = self.advance();
        }

        // Record body start
        const body_start = self.index;

        // Scan forward for 'end <handlerName>'
        const body_end = try self.findEnd(name);

        // Skip past 'end', spaces, handler name, and EOL
        _ = self.advance(); // KW_END
        self.skipSpaces();
        if (self.peek() == .ST_ID) {
            _ = self.advance(); // handler name after end
        }
        // Skip trailing EOL
        if (self.peek() == .ST_EOL) {
            _ = self.advance();
        }

        return .{
            .handler_type = handler_type,
            .name = name,
            .params = params.toOwnedSlice(self.allocator) catch return error.OutOfMemory,
            .body_start = body_start,
            .body_end = body_end,
        };
    }

    fn findEnd(self: *Parser, handler_name: []const u8) ParseError!usize {
        const saved = self.index;
        var i = self.index;
        while (i < self.tokens.len) {
            if (self.tokens[i].tag == .KW_END) {
                // Look ahead past spaces for matching handler name
                var j = i + 1;
                while (j < self.tokens.len and self.tokens[j].tag == .ST_SPC) {
                    j += 1;
                }
                if (j < self.tokens.len and self.tokens[j].tag == .ST_ID) {
                    const end_name = self.source[self.tokens[j].loc.start..self.tokens[j].loc.end];
                    if (std.ascii.eqlIgnoreCase(end_name, handler_name)) {
                        self.index = i; // Position at KW_END for caller
                        return i; // body_end is the index of KW_END
                    } else {
                        // Mismatched end name
                        self.index = saved;
                        return error.UnmatchedEnd;
                    }
                }
            }
            i += 1;
        }
        self.index = saved;
        return error.UnexpectedEof;
    }

    fn advance(self: *Parser) Token {
        if (self.index >= self.tokens.len) {
            return .{ .tag = .ST_EOF, .loc = .{ .start = self.source.len, .end = self.source.len } };
        }
        const tok = self.tokens[self.index];
        self.index += 1;
        return tok;
    }

    fn expect(self: *Parser, tag: Tag) ParseError!Token {
        if (self.peek() != tag) {
            return error.UnexpectedToken;
        }
        return self.advance();
    }

    fn peek(self: *Parser) Tag {
        if (self.index >= self.tokens.len) return .ST_EOF;
        return self.tokens[self.index].tag;
    }

    fn skipSpaces(self: *Parser) void {
        while (self.peek() == .ST_SPC) {
            _ = self.advance();
        }
    }

    fn skipWhitespace(self: *Parser) void {
        while (self.peek() == .ST_SPC or self.peek() == .ST_EOL) {
            _ = self.advance();
        }
    }
};

// --- Helper: lex source into token slice ---
const Lexer = @import("lexer.zig").Lexer;

fn lexAll(allocator: std.mem.Allocator, source: []const u8) ![]Token {
    var lex = Lexer.init(source);
    var tokens: std.ArrayList(Token) = .empty;
    errdefer tokens.deinit(allocator);
    while (true) {
        const tok = lex.next();
        try tokens.append(allocator, tok);
        if (tok.tag == .ST_EOF) break;
    }
    return tokens.toOwnedSlice(allocator);
}

// --- Tests ---
const testing = std.testing;

test "parse single on handler with no params" {
    const source = "on mouseUp\n  put \"hello\"\nend mouseUp\n";
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 1), script.handlers.len);
    try testing.expectEqualStrings("mouseUp", script.handlers[0].name);
    try testing.expectEqual(HandlerType.message, script.handlers[0].handler_type);
    try testing.expectEqual(@as(usize, 0), script.handlers[0].params.len);
}

test "parse handler with multiple params" {
    const source = "on mouseUp param1, param2\n  put param1\nend mouseUp\n";
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 1), script.handlers.len);
    try testing.expectEqual(@as(usize, 2), script.handlers[0].params.len);
    try testing.expectEqualStrings("param1", script.handlers[0].params[0]);
    try testing.expectEqualStrings("param2", script.handlers[0].params[1]);
}

test "parse function handler" {
    const source = "function myFunc arg1\n  return arg1 + 1\nend myFunc\n";
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 1), script.handlers.len);
    try testing.expectEqualStrings("myFunc", script.handlers[0].name);
    try testing.expectEqual(HandlerType.function, script.handlers[0].handler_type);
    try testing.expectEqual(@as(usize, 1), script.handlers[0].params.len);
    try testing.expectEqualStrings("arg1", script.handlers[0].params[0]);
}

test "parse multiple handlers" {
    const source =
        \\on mouseUp
        \\  put "hello"
        \\end mouseUp
        \\
        \\function addOne x
        \\  return x + 1
        \\end addOne
        \\
    ;
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 2), script.handlers.len);
    try testing.expectEqualStrings("mouseUp", script.handlers[0].name);
    try testing.expectEqual(HandlerType.message, script.handlers[0].handler_type);
    try testing.expectEqualStrings("addOne", script.handlers[1].name);
    try testing.expectEqual(HandlerType.function, script.handlers[1].handler_type);
}

test "error on mismatched end name" {
    const source = "on mouseUp\n  put \"hello\"\nend wrongName\n";
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const result = parser.parse();
    try testing.expectError(error.UnmatchedEnd, result);
}

test "error on missing end" {
    const source = "on mouseUp\n  put \"hello\"\n";
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const result = parser.parse();
    try testing.expectError(error.UnexpectedEof, result);
}
