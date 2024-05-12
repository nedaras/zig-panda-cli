const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @cImport({
    @cInclude("cregex.h");
});

const REGEX_T_SIZEOF = c.sizeof_regex_t;
const REGEX_T_ALIGNOF = c.alignof_regex_t;

const Self = @This();

allocator: Allocator,
regex: *c.regex_t,

pub const Match = struct {
    start: u32,
    end: u32,
};

// TODO: remove the null terminated strings wtf and make support for windows and make string format /{reg}/gI...
pub fn init(allocator: Allocator, regex: [:0]const u8) !Self {
    const slice = try allocator.alignedAlloc(u8, REGEX_T_ALIGNOF, REGEX_T_SIZEOF);
    errdefer allocator.free(slice[0..REGEX_T_SIZEOF]);

    const reg: *c.regex_t = @ptrCast(slice.ptr);
    if (c.regcomp(reg, regex, c.REG_EXTENDED) != 0) {
        return error.InvalidRegex;
    }

    return .{
        .allocator = allocator,
        .regex = reg,
    };
}

pub fn match(self: Self, input: []const u8) !?Match {
    var arr = try std.ArrayListUnmanaged(u8).initCapacity(self.allocator, input.len + 1);
    defer arr.deinit(self.allocator);

    try arr.appendSlice(self.allocator, input);
    try arr.append(self.allocator, '\x00');

    const slice = arr.items[0 .. arr.items.len - 1 :0];
    var m: c.regmatch_t = undefined;

    if (c.regexec(self.regex, slice, 1, &m, 0) != 0) return null;
    return .{
        .start = @intCast(m.rm_so),
        .end = @intCast(m.rm_eo),
    };
}

pub fn deinit(self: *Self) void {
    var slice: [*]u8 = @ptrCast(self.regex);

    c.regfree(self.regex);
    self.allocator.free(slice[0..REGEX_T_SIZEOF]);
}
