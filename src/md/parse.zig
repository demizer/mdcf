const std = @import("std");
const mem = std.mem;

/// Function prototype for a State Transition in the Parser
pub const StateTransition = fn (lexer: *Lexer) anyerror!?AstNode;

/// A non-stream Markdown parser which constructs a tree of Nodes
pub const Parser = struct {
    allocator: *Allocator,
    state: State,
    // copy_strings: bool,
    // Stores parent nodes and un-combined Values.
    // stack: Array,

    const State = enum {
        Start,
    };

    pub fn init(
        allocator: *Allocator,
    ) Parser {
        return Parser{
            .allocator = allocator,
            .state = .Start,
            // .copy_strings = copy_strings,
            // .stack = Array.init(allocator),
        };
    }

    // pub fn deinit(p: *Parser) void {
    //     p.stack.deinit();
    // }

    // pub fn reset(p: *Parser) void {
    //     p.state = .Simple;
    //     p.stack.shrink(0);
    // }

    // pub fn parse(p: *Parser, input: []const u8) !ValueTree {}
};

test "parser test 1" {
    var p = Parser.init(testing.allocator, false);
    // defer p.deinit();

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

    // var tree = try p.parse(s);
    // defer tree.deinit();

    // var root = tree.root;

    // var image = root.Object.get("Image").?.value;

    // const width = image.Object.get("Width").?.value;
    // testing.expect(width.Integer == 800);

    // const height = image.Object.get("Height").?.value;
    // testing.expect(height.Integer == 600);
}
