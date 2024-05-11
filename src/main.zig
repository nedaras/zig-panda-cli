const std = @import("std");
const color = @import("cli/colors.zig");
const cursor = @import("cli/cursor.zig");

fn stty() !void {
    // only on linux now idk about mac
    var p1 = std.ChildProcess.init(&.{ "stty", "-F", "/dev/tty", "cbreak", "min", "1" }, std.heap.page_allocator);
    try p1.spawn();
    _ = try p1.wait();

    var p2 = std.ChildProcess.init(&.{ "stty", "-F", "/dev/tty", "-echo" }, std.heap.page_allocator);
    try p2.spawn();
    _ = try p2.wait();
}

pub fn main() !void {

    //try color.stdoutPrint("&42&30 panda &0  Hello world.\n\n", .{});
    //try color.stdoutPrint("  &45&97 #1 &0  &91▶ Directory is not empty!", .{});
    //try color.stdoutPrint("\x1B[2K\x1B[1Ghello world" ++ cursor.save ++ "  &91Oh my gad error" ++ cursor.restore, .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    try stty();

    const stdout_file = std.io.getStdOut();
    const stdin_file = std.io.getStdIn();

    var bw = std.io.bufferedWriter(stdout_file.writer());
    const stdout = bw.writer();

    //try stdout.writeAll("\x1B[?25l");
    try color.translate(stdout, "&42&30 panda &0  Hello world.\n\n");
    try color.translate(stdout, "  &45&97 #1 &0  whats poping?\n        &2write a number" ++ cursor.save ++ "  &91▶ Directory is not empty!" ++ cursor.restore);

    try bw.flush();

    var placeholder = std.ArrayList(u8).init(allocator);
    defer placeholder.deinit();

    while (true) {
        std.debug.print("\x1B[2K\x1B[1Gplaceholder: {s}", .{placeholder.items});
        var buf: [3]u8 = undefined;
        const size = try stdin_file.read(&buf);
        const key = buf[0..size];

        if (key.len == 1 and key[0] == '\x7F' and placeholder.items.len > 0) { // handle x arrow keys
            _ = placeholder.pop();
            continue;
        }
        if (key.len == 1) { // and only accept writable asci chars so
            try placeholder.appendSlice(key);
        }
    }
}
