const std = @import("std");
const colors = @import("cli/colors.zig");

pub fn main() !void {
    std.debug.print("&0 = " ++ colors.comptimeTranslate("&0ABC") ++ "   &1 = " ++ colors.comptimeTranslate("&1AB\n"), .{});
    std.debug.print("&2 = " ++ colors.comptimeTranslate("&2ABC") ++ "   &3 = " ++ colors.comptimeTranslate("&3AB\n"), .{});
    std.debug.print("&4 = " ++ colors.comptimeTranslate("&4ABC") ++ "   &5 = " ++ colors.comptimeTranslate("&5AB\n"), .{});
    std.debug.print("&6 = " ++ colors.comptimeTranslate("&6ABC") ++ "   &7 = " ++ colors.comptimeTranslate("&7AB\n"), .{});
    std.debug.print("&8 = " ++ colors.comptimeTranslate("&8ABC") ++ "   &9 = " ++ colors.comptimeTranslate("&9AB\n"), .{});
    std.debug.print("&a = " ++ colors.comptimeTranslate("&aABC") ++ "   &b = " ++ colors.comptimeTranslate("&bAB\n"), .{});
    std.debug.print("&c = " ++ colors.comptimeTranslate("&cABC") ++ "   &d = " ++ colors.comptimeTranslate("&dAB\n"), .{});
    std.debug.print("&e = " ++ colors.comptimeTranslate("&eABC") ++ "   &f = " ++ colors.comptimeTranslate("&fAB\n"), .{});
    std.debug.print("&k = " ++ colors.comptimeTranslate("&kABC") ++ "   &l = " ++ colors.comptimeTranslate("&lAB\n"), .{});
    std.debug.print("&m = " ++ colors.comptimeTranslate("&mABC") ++ "   &n = " ++ colors.comptimeTranslate("&nAB\n"), .{});
    std.debug.print("&o = " ++ colors.comptimeTranslate("&oABC") ++ "   &r = " ++ colors.comptimeTranslate("&rAB\n"), .{});
    std.debug.print(colors.comptimeTranslate("&o&k&a&l&m&nHello World!\n"), .{});
    //while (true) {
    //defer frame += 1;
    //try stdout.print("\x1B[2F\x1B[G\x1B[2Kcount is:\n{}\n", .{frame});
    //}

    //try stdout.print("\x1B[2F\x1B[G\x1B[2Kbye\nworld\n", .{});

    //try stdout.print("\n\n", .{});
    //try stdout.print("\x1B[2Khello world", .{});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
