const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;

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

    // Loop over tokens and print
    var lex = Lexer.init(source);
    while (true) {
        const tok = lex.next();
        const text = source[tok.loc.start..tok.loc.end];
        std.debug.print("{s}: \"{s}\"\n", .{ @tagName(tok.tag), text });
        if (tok.tag == .ST_EOF) break;
    }
}
