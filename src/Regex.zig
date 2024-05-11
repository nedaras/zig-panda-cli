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

// TODO: remove the null terminated strings wtf
pub fn init(allocator: Allocator, regex: [:0]const u8) !Self {
    const slice = try allocator.alignedAlloc(u8, REGEX_T_ALIGNOF, REGEX_T_SIZEOF);
    const reg: *c.regex_t = @ptrCast(slice.ptr);

    if (c.regcomp(reg, regex, 0) != 0) {
        return error.InvalidRegex;
    }

    std.debug.print("reg: {}\n", .{c.regexec(reg, "as use bobas!!", 0, 0, 0)});
    std.debug.print("reg: {}\n", .{c.regexec(reg, "false", 0, 0, 0)});

    return .{
        .allocator = allocator,
        .regex = reg,
    };
}

pub fn cmp(input: [:0]const u8) bool {
    _ = input;
}

pub fn deinit(self: *Self) void {
    var slice: [*]u8 = @ptrCast(self.regex);

    c.regfree(self.regex);
    self.allocator.free(slice[0..REGEX_T_SIZEOF]);
}
