pub const AstNodeType = enum {
    AtxHeader,
};

const AstNode = struct {
    Type: AstNodeType,
    Text: []const u8,
};
