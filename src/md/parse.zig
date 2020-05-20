const std = @import("std");
const mem = std.mem;
const test_util = @import("test_util.zig");
const doc = @import("document.zig");
const Lexer = @import("lexer.zig").Lexer;
const TokenId = @import("token.zig").TokenId;
usingnamespace @import("log.zig");

/// Function prototype for a State Transition in the Parser
pub const StateTransition = fn (lexer: *Lexer) anyerror!?AstNode;

pub const Node = struct {
    Id: Id,
    Value: []const u8,

    PositionStart: Position,
    PositionEnd: Position,

    Children: std.ArrayList(Node),

    pub const Position = struct {
        Line: u32,
        Column: u32,
        Offset: u32,
    };

    pub const Id = enum {
        NodeAtxHeading,
    };
};

/// A non-stream Markdown parser which constructs a tree of Nodes
pub const Parser = struct {
    allocator: *mem.Allocator,
    root: std.ArrayList(Node),
    state: State,
    lex: Lexer,

    const State = enum {
        Start,
    };

    pub fn init(
        allocator: *mem.Allocator,
    ) Parser {
        return Parser{
            .allocator = allocator,
            .state = .Start,
            .root = std.ArrayList(Node).init(allocator),
            .lex = undefined,
        };
    }

    pub fn deinit(self: *Parser) void {
        self.root.deinit();
        self.lex.deinit();
    }

    pub fn parse(self: *Parser, input: []const u8) !void {
        self.lex = try Lexer.init(self.allocator, input);
        use_rfc3339_date_handler();
        log.Debugf("input:\n{}\n-- END OF TEST --\n", .{input});
        while (true) {
            if (try self.lex.next()) |tok| {
                if (tok.ID == TokenId.EOF) {
                    log.Debug("Found EOF");
                    break;
                }
            }
        }
    }
};

test "parser test 1" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    const input = try test_util.getTest(allocator, 32);

    // TODO: move this somplace else
    use_rfc3339_date_handler();

    log.Debugf("test:\n{}\n-- END OF TEST --\n", .{input});

    var p = Parser.init(std.testing.allocator);
    defer p.deinit();

    // Used https://codebeautify.org/xmltojson to convert ast from spec to json
    const expect =
        \\{
        \\  "document": {
        \\    "heading": [
        \\      {
        \\        "text": "foo",
        \\        "level": "1"
        \\      },
        \\      {
        \\        "text": "foo",
        \\        "level": "2"
        \\      },
        \\      {
        \\        "text": "foo",
        \\        "level": "3"
        \\      },
        \\      {
        \\        "text": "foo",
        \\        "level": "4"
        \\      },
        \\      {
        \\        "text": "foo",
        \\        "level": "5"
        \\      },
        \\      {
        \\        "text": "foo",
        \\        "level": "6"
        \\      }
        \\    ],
        \\  }
        \\}
    ;
    var out = p.parse(input);
}
