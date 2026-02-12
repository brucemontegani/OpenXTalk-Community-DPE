const std = @import("std");
const token_mod = @import("token.zig");
const ast_mod = @import("ast.zig");
const Token = token_mod.Token;
const Tag = token_mod.Tag;
const Handler = ast_mod.Handler;
const HandlerType = ast_mod.HandlerType;
const Script = ast_mod.Script;
const Statement = ast_mod.Statement;
const ExprSpan = ast_mod.ExprSpan;
const PutVariant = ast_mod.PutVariant;

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
                h.deinit(self.allocator);
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

        // Parse body statements until 'end <handlerName>'
        const body = try self.parseStatements(name);

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
            .body = body,
        };
    }

    /// Parse statements until we see `end <handler_name>` (KW_END + ST_ID matching handler_name).
    fn parseStatements(self: *Parser, handler_name: []const u8) ParseError![]const Statement {
        var stmts: std.ArrayList(Statement) = .empty;
        errdefer {
            ast_mod.deinitStatements(stmts.items, self.allocator);
            stmts.deinit(self.allocator);
        }

        while (true) {
            self.skipWhitespace();
            const tag = self.peek();

            if (tag == .ST_EOF) return error.UnexpectedEof;

            // Check for 'end <handlerName>'
            if (tag == .KW_END) {
                if (self.isEndHandler(handler_name)) break;
                return error.UnmatchedEnd;
            }

            const stmt = try self.parseStatement();
            stmts.append(self.allocator, stmt) catch return error.OutOfMemory;
        }

        return stmts.toOwnedSlice(self.allocator) catch return error.OutOfMemory;
    }

    /// Parse statements until we see KW_END + KW_IF, or KW_ELSE at current nesting level.
    /// Returns the statements and sets `hit_else` to true if we stopped at KW_ELSE.
    const StatementsResult = struct {
        stmts: []const Statement,
        hit_else: bool,
    };

    fn parseStatementsUntilEndIf(self: *Parser) ParseError!StatementsResult {
        var stmts: std.ArrayList(Statement) = .empty;
        errdefer {
            ast_mod.deinitStatements(stmts.items, self.allocator);
            stmts.deinit(self.allocator);
        }

        while (true) {
            self.skipWhitespace();
            const tag = self.peek();

            if (tag == .ST_EOF) return error.UnexpectedEof;

            // Check for 'else'
            if (tag == .KW_ELSE) {
                return .{
                    .stmts = stmts.toOwnedSlice(self.allocator) catch return error.OutOfMemory,
                    .hit_else = true,
                };
            }

            // Check for 'end if'
            if (tag == .KW_END) {
                if (self.isEndKeyword(.KW_IF)) {
                    return .{
                        .stmts = stmts.toOwnedSlice(self.allocator) catch return error.OutOfMemory,
                        .hit_else = false,
                    };
                }
                // Could be 'end repeat' inside a nested repeat — not valid here
                return error.UnmatchedEnd;
            }

            const stmt = try self.parseStatement();
            stmts.append(self.allocator, stmt) catch return error.OutOfMemory;
        }
    }

    fn parseStatementsUntilEndRepeat(self: *Parser) ParseError![]const Statement {
        var stmts: std.ArrayList(Statement) = .empty;
        errdefer {
            ast_mod.deinitStatements(stmts.items, self.allocator);
            stmts.deinit(self.allocator);
        }

        while (true) {
            self.skipWhitespace();
            const tag = self.peek();

            if (tag == .ST_EOF) return error.UnexpectedEof;

            // Check for 'end repeat'
            if (tag == .KW_END) {
                if (self.isEndKeyword(.KW_REPEAT)) {
                    return stmts.toOwnedSlice(self.allocator) catch return error.OutOfMemory;
                }
                return error.UnmatchedEnd;
            }

            const stmt = try self.parseStatement();
            stmts.append(self.allocator, stmt) catch return error.OutOfMemory;
        }
    }

    /// Check if current position is `end <name>` without consuming tokens.
    fn isEndHandler(self: *Parser, handler_name: []const u8) bool {
        var i = self.index;
        if (i >= self.tokens.len or self.tokens[i].tag != .KW_END) return false;
        i += 1;
        // skip spaces
        while (i < self.tokens.len and self.tokens[i].tag == .ST_SPC) i += 1;
        if (i >= self.tokens.len or self.tokens[i].tag != .ST_ID) return false;
        const end_name = self.source[self.tokens[i].loc.start..self.tokens[i].loc.end];
        return std.ascii.eqlIgnoreCase(end_name, handler_name);
    }

    /// Check if current position is `end <keyword>` without consuming tokens.
    fn isEndKeyword(self: *Parser, keyword: Tag) bool {
        var i = self.index;
        if (i >= self.tokens.len or self.tokens[i].tag != .KW_END) return false;
        i += 1;
        while (i < self.tokens.len and self.tokens[i].tag == .ST_SPC) i += 1;
        if (i >= self.tokens.len) return false;
        return self.tokens[i].tag == keyword;
    }

    /// Consume `end <keyword>` (e.g., end if, end repeat).
    fn consumeEndKeyword(self: *Parser, keyword: Tag) ParseError!void {
        _ = try self.expect(.KW_END);
        self.skipSpaces();
        _ = try self.expect(keyword);
        // Skip trailing EOL
        if (self.peek() == .ST_EOL) {
            _ = self.advance();
        }
    }

    fn parseStatement(self: *Parser) ParseError!Statement {
        self.skipSpaces();
        const tag = self.peek();

        return switch (tag) {
            .KW_PUT => self.parsePut(),
            .KW_RETURN => self.parseReturn(),
            .KW_IF => self.parseIf(),
            .KW_REPEAT => self.parseRepeat(),
            .ST_ID => self.parseCommandCall(),
            .ST_EOL => {
                _ = self.advance();
                return self.parseStatement();
            },
            else => error.UnexpectedToken,
        };
    }

    fn parsePut(self: *Parser) ParseError!Statement {
        _ = self.advance(); // consume KW_PUT
        self.skipSpaces();

        const source = self.parseExprUntil(&.{ .KW_INTO, .KW_AFTER, .KW_BEFORE });

        // Determine variant
        const variant_tag = self.peek();
        const variant: PutVariant = switch (variant_tag) {
            .KW_INTO => .into,
            .KW_AFTER => .after,
            .KW_BEFORE => .before,
            else => return error.UnexpectedToken,
        };
        _ = self.advance(); // consume variant keyword
        self.skipSpaces();

        const target = self.parseExprUntil(&.{.ST_EOL});

        // Skip EOL
        if (self.peek() == .ST_EOL) {
            _ = self.advance();
        }

        return .{ .put = .{
            .source = source,
            .variant = variant,
            .target = target,
        } };
    }

    fn parseReturn(self: *Parser) ParseError!Statement {
        _ = self.advance(); // consume KW_RETURN
        self.skipSpaces();

        if (self.peek() == .ST_EOL or self.peek() == .ST_EOF) {
            if (self.peek() == .ST_EOL) _ = self.advance();
            return .{ .return_stmt = .{ .value = null } };
        }

        const expr = self.parseExprUntil(&.{.ST_EOL});

        if (self.peek() == .ST_EOL) {
            _ = self.advance();
        }

        return .{ .return_stmt = .{ .value = expr } };
    }

    fn parseIf(self: *Parser) ParseError!Statement {
        _ = self.advance(); // consume KW_IF
        self.skipSpaces();

        // Parse condition until KW_THEN
        const condition = self.parseExprUntil(&.{.KW_THEN});
        _ = try self.expect(.KW_THEN); // consume 'then'
        self.skipSpaces();

        // Check if single-line (no EOL immediately after 'then')
        if (self.peek() != .ST_EOL and self.peek() != .ST_EOF) {
            // Single-line if: parse one statement on same line
            const stmt = try self.parseStatement();
            var then_body: std.ArrayList(Statement) = .empty;
            then_body.append(self.allocator, stmt) catch return error.OutOfMemory;

            const empty_else = self.allocator.alloc(Statement, 0) catch return error.OutOfMemory;

            return .{ .if_stmt = .{
                .condition = condition,
                .then_body = then_body.toOwnedSlice(self.allocator) catch return error.OutOfMemory,
                .else_body = empty_else,
                .single_line = true,
            } };
        }

        // Multi-line if
        // Skip the EOL after 'then'
        if (self.peek() == .ST_EOL) _ = self.advance();

        const result = try self.parseStatementsUntilEndIf();

        if (result.hit_else) {
            // Consume 'else'
            _ = self.advance(); // KW_ELSE
            // Skip EOL after else
            if (self.peek() == .ST_EOL) _ = self.advance();

            // Parse else body until 'end if'
            const else_result = try self.parseStatementsUntilEndIf();
            if (else_result.hit_else) return error.UnexpectedToken; // double else

            // Consume 'end if'
            try self.consumeEndKeyword(.KW_IF);

            return .{ .if_stmt = .{
                .condition = condition,
                .then_body = result.stmts,
                .else_body = else_result.stmts,
                .single_line = false,
            } };
        }

        // No else — consume 'end if'
        try self.consumeEndKeyword(.KW_IF);

        const empty_else = self.allocator.alloc(Statement, 0) catch return error.OutOfMemory;

        return .{ .if_stmt = .{
            .condition = condition,
            .then_body = result.stmts,
            .else_body = empty_else,
            .single_line = false,
        } };
    }

    fn parseRepeat(self: *Parser) ParseError!Statement {
        _ = self.advance(); // consume KW_REPEAT
        self.skipSpaces();

        var counter: ?ast_mod.RepeatCounter = null;

        // Check for 'with' form: repeat with <var> = <start> to <end>
        if (self.peek() == .KW_WITH) {
            _ = self.advance(); // consume 'with'
            self.skipSpaces();

            const var_tok = try self.expect(.ST_ID);
            const var_name = self.source[var_tok.loc.start..var_tok.loc.end];
            self.skipSpaces();

            _ = try self.expect(.ST_OP); // '='
            self.skipSpaces();

            const start_expr = self.parseExprUntil(&.{.KW_TO});
            _ = try self.expect(.KW_TO); // consume 'to'
            self.skipSpaces();

            const end_expr = self.parseExprUntil(&.{.ST_EOL});

            counter = .{
                .var_name = var_name,
                .start = start_expr,
                .end = end_expr,
            };
        }

        // Skip EOL
        if (self.peek() == .ST_EOL) _ = self.advance();

        // Parse body until 'end repeat'
        const body = try self.parseStatementsUntilEndRepeat();

        // Consume 'end repeat'
        try self.consumeEndKeyword(.KW_REPEAT);

        return .{ .repeat_stmt = .{
            .counter = counter,
            .body = body,
        } };
    }

    fn parseCommandCall(self: *Parser) ParseError!Statement {
        const name_tok = self.advance(); // consume ST_ID (command name)
        const name = self.source[name_tok.loc.start..name_tok.loc.end];
        self.skipSpaces();

        if (self.peek() == .ST_EOL or self.peek() == .ST_EOF) {
            if (self.peek() == .ST_EOL) _ = self.advance();
            return .{ .command_call = .{
                .name = name,
                .args = null,
            } };
        }

        const args = self.parseExprUntil(&.{.ST_EOL});

        if (self.peek() == .ST_EOL) {
            _ = self.advance();
        }

        return .{ .command_call = .{
            .name = name,
            .args = args,
        } };
    }

    /// Scan tokens until hitting one of the stop tags. Returns an ExprSpan
    /// covering the consumed tokens (excluding trailing spaces).
    fn parseExprUntil(self: *Parser, stop_tags: []const Tag) ExprSpan {
        const start = self.index;
        var end = self.index;

        while (self.index < self.tokens.len) {
            const tag = self.tokens[self.index].tag;
            if (tag == .ST_EOF) break;

            for (stop_tags) |stop| {
                if (tag == stop) {
                    return .{ .start = start, .end = end };
                }
            }

            self.index += 1;
            // Track end, skipping trailing spaces
            if (tag != .ST_SPC) {
                end = self.index;
            }
        }

        return .{ .start = start, .end = end };
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
        while (self.peek() == .ST_SPC or self.peek() == .ST_EOL or self.peek() == .ST_COM) {
            _ = self.advance();
        }
    }

    /// Reconstruct source text from a token span.
    pub fn spanText(self: *const Parser, span: ExprSpan) []const u8 {
        if (span.start >= self.tokens.len or span.end == 0 or span.start >= span.end) return "";
        const first = self.tokens[span.start].loc.start;
        const last_idx = if (span.end - 1 < self.tokens.len) span.end - 1 else self.tokens.len - 1;
        const last = self.tokens[last_idx].loc.end;
        return self.source[first..last];
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
    const source = "on mouseUp\n  put \"hello\" into x\nend mouseUp\n";
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 1), script.handlers.len);
    try testing.expectEqualStrings("mouseUp", script.handlers[0].name);
    try testing.expectEqual(HandlerType.message, script.handlers[0].handler_type);
    try testing.expectEqual(@as(usize, 0), script.handlers[0].params.len);
    try testing.expectEqual(@as(usize, 1), script.handlers[0].body.len);

    // Verify it parsed as a put statement
    switch (script.handlers[0].body[0]) {
        .put => |p| {
            try testing.expectEqual(PutVariant.into, p.variant);
        },
        else => return error.UnexpectedToken,
    }
}

test "parse handler with multiple params" {
    const source = "on mouseUp param1, param2\n  put param1 into x\nend mouseUp\n";
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

    // Body should have a return statement
    try testing.expectEqual(@as(usize, 1), script.handlers[0].body.len);
    switch (script.handlers[0].body[0]) {
        .return_stmt => |r| {
            try testing.expect(r.value != null);
        },
        else => return error.UnexpectedToken,
    }
}

test "parse multiple handlers" {
    const source =
        \\on mouseUp
        \\  put "hello" into x
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
    const source = "on mouseUp\n  put \"hello\" into x\nend wrongName\n";
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const result = parser.parse();
    try testing.expectError(error.UnmatchedEnd, result);
}

test "error on missing end" {
    const source = "on mouseUp\n  put \"hello\" into x\n";
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const result = parser.parse();
    try testing.expectError(error.UnexpectedEof, result);
}

test "parse put statement" {
    const source = "on test\n  put \"hello\" into x\nend test\n";
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    const body = script.handlers[0].body;
    try testing.expectEqual(@as(usize, 1), body.len);
    switch (body[0]) {
        .put => |p| {
            try testing.expectEqual(PutVariant.into, p.variant);
            try testing.expectEqualStrings("\"hello\"", parser.spanText(p.source));
            try testing.expectEqualStrings("x", parser.spanText(p.target));
        },
        else => return error.UnexpectedToken,
    }
}

test "parse return with value and bare return" {
    const source = "function test\n  return 42\nend test\n";
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    switch (script.handlers[0].body[0]) {
        .return_stmt => |r| {
            try testing.expect(r.value != null);
            try testing.expectEqualStrings("42", parser.spanText(r.value.?));
        },
        else => return error.UnexpectedToken,
    }
}

test "parse bare return" {
    const source = "function test\n  return\nend test\n";
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    switch (script.handlers[0].body[0]) {
        .return_stmt => |r| {
            try testing.expectEqual(@as(?ExprSpan, null), r.value);
        },
        else => return error.UnexpectedToken,
    }
}

test "parse single-line if" {
    const source = "on test\n  if x > 0 then put \"yes\" into r\nend test\n";
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    switch (script.handlers[0].body[0]) {
        .if_stmt => |ifs| {
            try testing.expect(ifs.single_line);
            try testing.expectEqual(@as(usize, 1), ifs.then_body.len);
            try testing.expectEqual(@as(usize, 0), ifs.else_body.len);
        },
        else => return error.UnexpectedToken,
    }
}

test "parse multi-line if/else/end if" {
    const source =
        \\on test
        \\  if x > 0 then
        \\    put "yes" into r
        \\  else
        \\    put "no" into r
        \\  end if
        \\end test
        \\
    ;
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    switch (script.handlers[0].body[0]) {
        .if_stmt => |ifs| {
            try testing.expect(!ifs.single_line);
            try testing.expectEqual(@as(usize, 1), ifs.then_body.len);
            try testing.expectEqual(@as(usize, 1), ifs.else_body.len);
        },
        else => return error.UnexpectedToken,
    }
}

test "parse repeat with counter" {
    const source =
        \\on test
        \\  repeat with i = 1 to 10
        \\    put i into x
        \\  end repeat
        \\end test
        \\
    ;
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    switch (script.handlers[0].body[0]) {
        .repeat_stmt => |rep| {
            try testing.expect(rep.counter != null);
            try testing.expectEqualStrings("i", rep.counter.?.var_name);
            try testing.expectEqual(@as(usize, 1), rep.body.len);
        },
        else => return error.UnexpectedToken,
    }
}

test "parse bare repeat (forever loop)" {
    const source =
        \\on test
        \\  repeat
        \\    put "loop" into x
        \\  end repeat
        \\end test
        \\
    ;
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    switch (script.handlers[0].body[0]) {
        .repeat_stmt => |rep| {
            try testing.expectEqual(@as(?ast_mod.RepeatCounter, null), rep.counter);
            try testing.expectEqual(@as(usize, 1), rep.body.len);
        },
        else => return error.UnexpectedToken,
    }
}

test "parse command call" {
    const source = "on test\n  add 5 to x\nend test\n";
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    switch (script.handlers[0].body[0]) {
        .command_call => |cmd| {
            try testing.expectEqualStrings("add", cmd.name);
            try testing.expect(cmd.args != null);
        },
        else => return error.UnexpectedToken,
    }
}

test "parse multiple statements in one handler" {
    const source =
        \\on test
        \\  put "hello" into x
        \\  put "world" after x
        \\  return x
        \\end test
        \\
    ;
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 3), script.handlers[0].body.len);

    switch (script.handlers[0].body[1]) {
        .put => |p| try testing.expectEqual(PutVariant.after, p.variant),
        else => return error.UnexpectedToken,
    }
}

test "parse nested if inside repeat" {
    const source =
        \\on test
        \\  repeat with i = 1 to 10
        \\    if i > 5 then
        \\      put i into x
        \\    end if
        \\  end repeat
        \\end test
        \\
    ;
    const tokens = try lexAll(testing.allocator, source);
    defer testing.allocator.free(tokens);

    var parser = Parser.init(tokens, source, testing.allocator);
    const script = try parser.parse();
    defer script.deinit(testing.allocator);

    // Handler has one repeat statement
    try testing.expectEqual(@as(usize, 1), script.handlers[0].body.len);

    switch (script.handlers[0].body[0]) {
        .repeat_stmt => |rep| {
            // Repeat body has one if statement
            try testing.expectEqual(@as(usize, 1), rep.body.len);
            switch (rep.body[0]) {
                .if_stmt => |ifs| {
                    try testing.expectEqual(@as(usize, 1), ifs.then_body.len);
                },
                else => return error.UnexpectedToken,
            }
        },
        else => return error.UnexpectedToken,
    }
}
