const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("token.zig").Token;
const Parser = @import("parser.zig").Parser;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Read a filename from command-line args
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len < 2) {
        std.debug.print("Usage: mini-lc <filename>\n", .{});
        return;
    }

    // Read the file contents
    const source = try std.fs.cwd().readFileAlloc(allocator, args[1], 1024 * 1024);
    defer allocator.free(source);

    // Lex all tokens
    var lex = Lexer.init(source);
    var token_list: std.ArrayList(Token) = .empty;
    defer token_list.deinit(allocator);
    while (true) {
        const tok = lex.next();
        try token_list.append(allocator, tok);
        if (tok.tag == .ST_EOF) break;
    }
    const tokens = token_list.items;

    // Parse
    var parser = Parser.init(tokens, source, allocator);
    const script = parser.parse() catch |err| {
        std.debug.print("Parse error: {s}\n", .{@errorName(err)});
        return;
    };
    defer script.deinit(allocator);

    // Print parsed handlers
    for (script.handlers) |h| {
        std.debug.print("{f}\n", .{h});
    }
}
