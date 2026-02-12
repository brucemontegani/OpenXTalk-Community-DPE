const std = @import("std");

pub const Tag = enum {
    ST_UNDEFINED, // Control token (Undefined)
    ST_ERR, // Control token (Error)
    ST_EOF, // Control token (End of file)
    ST_EOL, // Control token (End of line)
    ST_SPC, // Space
    ST_COM, // Comment
    ST_OP, // Operator
    ST_MIN, // Minus
    ST_NUM, // Number literal
    ST_LP, // Left Parentheses
    ST_RP, // Right Parentheses
    ST_LB, // Left Bracket
    ST_RB, // Right Bracket
    ST_SEP, // Seperator (comma)
    ST_SEMI, // Semicolon
    ST_ID, // Identifier
    ST_ESC, // Escape
    ST_LIT, // String literal
    ST_LC, // Left Curly braces
    ST_RC, // Right Curly braces
    KW_ON,                                                                                                                                                                          
    KW_END,                                                                                                                                                                        
    KW_PUT,                                                                                                                                                                        
    KW_INTO,
    KW_AFTER,
    KW_BEFORE,
    KW_IF,
    KW_THEN,
    KW_ELSE,
    KW_REPEAT,
    KW_FUNCTION,
    KW_RETURN,
    KW_THE,
    KW_OF,
};

pub const keywords = std.StaticStringMap(Tag).initComptime(.{                                                                                                                                       
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

pub const Token = struct {
    tag: Tag,
    loc: struct { start: usize, end: usize },
};
