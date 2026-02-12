const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("token.zig").Token;
const Parser = @import("parser.zig").Parser;
const ast = @import("ast.zig");

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
        printHandler(&parser, h);
    }
}

fn printHandler(parser: *const Parser, h: ast.Handler) void {
    const type_str = switch (h.handler_type) {
        .message => "message",
        .function => "function",
    };
    std.debug.print("Handler(type={s}, name=\"{s}\", params=[", .{ type_str, h.name });
    for (h.params, 0..) |p, i| {
        if (i > 0) std.debug.print(", ", .{});
        std.debug.print("\"{s}\"", .{p});
    }
    std.debug.print("], body={d} statements)\n", .{h.body.len});

    for (h.body) |stmt| {
        printStatement(parser, stmt, 1);
    }

    std.debug.print("\n", .{});
}

fn printIndent(indent: usize) void {
    for (0..indent) |_| {
        std.debug.print("  ", .{});
    }
}

fn printStatement(parser: *const Parser, stmt: ast.Statement, indent: usize) void {
    printIndent(indent);

    switch (stmt) {
        .put => |p| {
            const variant_str = switch (p.variant) {
                .into => "into",
                .after => "after",
                .before => "before",
            };
            std.debug.print("PutStatement(variant={s}, source=\"{s}\", target=\"{s}\")\n", .{
                variant_str,
                parser.spanText(p.source),
                parser.spanText(p.target),
            });
        },
        .return_stmt => |r| {
            if (r.value) |v| {
                std.debug.print("ReturnStatement(value=\"{s}\")\n", .{parser.spanText(v)});
            } else {
                std.debug.print("ReturnStatement(value=none)\n", .{});
            }
        },
        .if_stmt => |ifs| {
            const form = if (ifs.single_line) "single-line" else "multi-line";
            std.debug.print("IfStatement(form={s}, condition=\"{s}\", then={d}, else={d})\n", .{
                form,
                parser.spanText(ifs.condition),
                ifs.then_body.len,
                ifs.else_body.len,
            });
            if (ifs.then_body.len > 0) {
                printIndent(indent + 1);
                std.debug.print("then:\n", .{});
                for (ifs.then_body) |s| {
                    printStatement(parser, s, indent + 2);
                }
            }
            if (ifs.else_body.len > 0) {
                printIndent(indent + 1);
                std.debug.print("else:\n", .{});
                for (ifs.else_body) |s| {
                    printStatement(parser, s, indent + 2);
                }
            }
        },
        .repeat_stmt => |rep| {
            if (rep.counter) |c| {
                std.debug.print("RepeatStatement(counter=\"{s}\", from=\"{s}\", to=\"{s}\", body={d})\n", .{
                    c.var_name,
                    parser.spanText(c.start),
                    parser.spanText(c.end),
                    rep.body.len,
                });
            } else {
                std.debug.print("RepeatStatement(forever, body={d})\n", .{rep.body.len});
            }
            if (rep.body.len > 0) {
                printIndent(indent + 1);
                std.debug.print("body:\n", .{});
                for (rep.body) |s| {
                    printStatement(parser, s, indent + 2);
                }
            }
        },
        .command_call => |cmd| {
            if (cmd.args) |a| {
                std.debug.print("CommandCall(name=\"{s}\", args=\"{s}\")\n", .{ cmd.name, parser.spanText(a) });
            } else {
                std.debug.print("CommandCall(name=\"{s}\", args=none)\n", .{cmd.name});
            }
        },
    }
}
