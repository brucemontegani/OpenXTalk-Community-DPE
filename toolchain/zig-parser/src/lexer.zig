const token_mod = @import("token.zig");
const std = @import("std");
const Token = token_mod.Token;
const Tag = token_mod.Tag;

pub const Lexer = struct {
    source: []const u8,
    index: usize,

    pub fn init(source: []const u8) Lexer {
        return Lexer{
            .source = source,
            .index = 0,
        };
    }

    pub fn next(self: *Lexer) Token {
        const start = self.index;

        // Check for end of input first
        if (self.index >= self.source.len) {
            return .{
                .tag = .ST_EOF,
                .loc = .{ .start = start, .end = start },
            };
        }

        const c = self.source[self.index];

        // const tag: Tag = switch (c) {
        switch (c) {
            ' ', '\t' => {
                // consume while whitespace...
                while (self.index < self.source.len and
                    (self.source[self.index] == ' ' or self.source[self.index] == '\t'))
                {
                    advance(self);
                }
                return .{
                    .tag = .ST_SPC,
                    .loc = .{ .start = start, .end = self.index },
                };
            },
            'a'...'z', 'A'...'Z', '_' => {
                // consume while alphanumeric...
                while (self.index < self.source.len and
                    (std.ascii.isAlphanumeric(self.source[self.index]) or self.source[self.index] == '_'))
                {
                    advance(self);
                }
                var lower_buf: [64]u8 = undefined;
                const text = self.source[start..self.index];
                // If identifier exceeds the buffer, it's definitely not a keyword   
                if (text.len <= lower_buf.len) {                                                                                                                                                                
                    const lower = std.ascii.lowerString(&lower_buf, text);                                                                                                                                      
                    const tag = keywords.get(lower) orelse .ST_ID;
                    return .{ .tag = tag, .loc = .{ .start = start, .end = self.index } };
                } else {
                    return .{ .tag = .ST_ID, .loc = .{ .start = start, .end = self.index } };
                }            
            },
            '0'...'9' => {
                // consume while numeric...
                while (self.index < self.source.len and
                    (std.ascii.isDigit(self.source[self.index])))
                {
                    advance(self);
                }
                // Check for a decimal point followed by more digits
                if (self.index < self.source.len and self.source[self.index] == '.' and self.index + 1 < self.source.len and
                    std.ascii.isDigit(self.source[self.index + 1]))
                {
                    advance(self); // consume the '.'

                    while (self.index < self.source.len and
                        std.ascii.isDigit(self.source[self.index]))
                    {
                        advance(self);
                    }
                }

                return .{
                    .tag = .ST_NUM,
                    .loc = .{ .start = start, .end = self.index },
                };
            },
            '"' => {
                // consume until ending '"'...
                advance(self); // Skip opening quote
                while (self.index < self.source.len and
                    self.source[self.index] != '"')
                {
                    advance(self);
                }

                if (self.index < self.source.len) {
                    advance(self); // Skip closing quote
                    return .{
                        .tag = .ST_LIT,
                        .loc = .{ .start = start, .end = self.index },
                    };
                }
                return .{
                    .tag = .ST_ERR, // No ending closing quote
                    .loc = .{ .start = start, .end = self.index },
                };
            },
            '-' => {
                // Look ahead one character to determine if it is a comment or a "minus".
                if (self.index + 1 < self.source.len and
                    self.source[self.index + 1] == '-') // Its a comment
                {
                    while (self.index < self.source.len and
                        (self.source[self.index] != '\n' and self.source[self.index] != '\r'))
                    {
                        advance(self);
                    }
                    return .{
                        .tag = .ST_COM,
                        .loc = .{ .start = start, .end = self.index },
                    };
                } else { // Its a minus
                    advance(self);
                    return .{
                        .tag = .ST_MIN,
                        .loc = .{ .start = start, .end = self.index },
                    };
                }
            },
            '(' => {
                advance(self);
                return .{ .tag = .ST_LP, .loc = .{ .start = start, .end = self.index } };
            },
            ')' => {
                advance(self);
                return .{
                    .tag = .ST_RP,
                    .loc = .{ .start = start, .end = self.index },
                };
            },
            '[' => {
                advance(self);
                return .{
                    .tag = .ST_LB,
                    .loc = .{ .start = start, .end = self.index },
                };
            },
            ']' => {
                advance(self);
                return .{
                    .tag = .ST_RB,
                    .loc = .{ .start = start, .end = self.index },
                };
            },
            '{' => {
                advance(self);
                return .{
                    .tag = .ST_LC,
                    .loc = .{ .start = start, .end = self.index },
                };
            },
            '}' => {
                advance(self);
                return .{
                    .tag = .ST_RC,
                    .loc = .{ .start = start, .end = self.index },
                };
            },
            ',' => {
                advance(self);
                return .{
                    .tag = .ST_SEP,
                    .loc = .{ .start = start, .end = self.index },
                };
            },
            ';' => {
                advance(self);
                return .{
                    .tag = .ST_SEMI,
                    .loc = .{ .start = start, .end = self.index },
                };
            },
            '\n' => {
                advance(self);
                return .{ .tag = .ST_EOL, .loc = .{ .start = start, .end = self.index } };
            },
            '\r' => {
                advance(self);
                // Handle \r\n as a single EOL
                if (self.index < self.source.len and self.source[self.index] == '\n') {
                    advance(self);
                }
                return .{ .tag = .ST_EOL, .loc = .{ .start = start, .end = self.index } };
            },
            '+', '*', '/', '=', '<', '>', '&' => {
                self.index += 1;
                return .{ .tag = .ST_OP, .loc = .{ .start = start, .end = self.index } };
            },
            else => {
                advance(self);
                return .{ .tag = .ST_ERR, .loc = .{ .start = start, .end = self.index } };
            },
        }
    }

    pub fn peek() u8 {}

    pub fn advance(self: *Lexer) void {
        self.index += 1;
    }
};

const keywords = std.StaticStringMap(Tag).initComptime(.{                                                                                                                                       
      .{ "on", .KW_ON },                                                                                                                                                                          
      .{ "end", .KW_END },                                                                                                                                                                        
      .{ "put", .KW_PUT },                                                                                                                                                                        
      .{ "into", .KW_INTO },
      .{ "after", .KW_AFTER },
      .{ "before", .KW_BEFORE },
      .{ "if", .KW_IF },
      .{ "then", .KW_THEN },
      .{ "else", .KW_ELSE },
      .{ "repeat", .KW_REPEAT },
      .{ "function", .KW_FUNCTION },
      .{ "return", .KW_RETURN },
      .{ "the", .KW_THE },
      .{ "of", .KW_OF },
  });





const testing = std.testing;

test "empty input" {
    var lex = Lexer.init("");
    const tok = lex.next();
    try testing.expectEqual(tok.tag, .ST_EOF);
}

test "simple identifier" {
    var lex = Lexer.init("name");
    const tok = lex.next();
    try testing.expectEqual(tok.tag, .ST_ID);
    try testing.expectEqualStrings("name", lex.source[tok.loc.start..tok.loc.end]);
}

test "keyword" {
    var lex = Lexer.init("put");
    const tok = lex.next();
    try testing.expectEqual(tok.tag, .KW_PUT);
    try testing.expectEqualStrings("put", lex.source[tok.loc.start..tok.loc.end]);
}

test "string literal" {
    var lex = Lexer.init("\"hello\"");
    const tok = lex.next();
    try testing.expectEqual(tok.tag, .ST_LIT);
    try testing.expectEqualStrings("\"hello\"", lex.source[tok.loc.start..tok.loc.end]);
}

test "number with decimal" {
    var lex = Lexer.init("3.14");
    const tok = lex.next();
    try testing.expectEqual(tok.tag, .ST_NUM);
    try testing.expectEqualStrings("3.14", lex.source[tok.loc.start..tok.loc.end]);
}

test "comment" {
    var lex = Lexer.init("-- this is a comment\nx");
    const tok = lex.next();
    try testing.expectEqual(tok.tag, .ST_COM);
    const tok2 = lex.next();
    try testing.expectEqual(tok2.tag, .ST_EOL);
}

test "put hello into x" {
    var lex = Lexer.init("put \"hello\" into x");
    const expected = [_]Tag{ .KW_PUT, .ST_SPC, .ST_LIT, .ST_SPC, .KW_INTO, .ST_SPC, .ST_ID, .ST_EOF };
    for (expected) |exp| {
        const tok = lex.next();
        try testing.expectEqual(tok.tag, exp);
    }
}

test "parentheses and operators" {
    var lex = Lexer.init("(a + b)");
    const expected = [_]Tag{ .ST_LP, .ST_ID, .ST_SPC, .ST_OP, .ST_SPC, .ST_ID, .ST_RP, .ST_EOF };
    for (expected) |exp| {
        const tok = lex.next();
        try testing.expectEqual(tok.tag, exp);
    }
}

test "minus vs comment" {
    var lex = Lexer.init("a - b -- comment");
    const expected = [_]Tag{ .ST_ID, .ST_SPC, .ST_MIN, .ST_SPC, .ST_ID, .ST_SPC, .ST_COM, .ST_EOF };
    for (expected) |exp| {
        const tok = lex.next();
        try testing.expectEqual(tok.tag, exp);
    }
}
