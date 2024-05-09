const std = @import("std");
const color = @import("cli/colors.zig");

pub fn main() !void {
    try color.stdoutPrint("&42&30 panda &0  Hello world.\n\n", .{});
    try color.stdoutPrint("  &45&97 #1 &0  Bye world?\n", .{});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
