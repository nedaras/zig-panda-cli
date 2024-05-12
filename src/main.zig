const std = @import("std");
const cursor = @import("cli/cursor.zig");
const color = @import("cli/colors.zig");
const Regex = @import("Regex.zig");

fn isToken(c: u8) bool {
    return c > 31 and c < 127;
}

fn stty() !void {
    // only on linux now idk about mac
    var p1 = std.ChildProcess.init(&.{ "stty", "-F", "/dev/tty", "cbreak", "min", "1" }, std.heap.page_allocator);
    try p1.spawn();
    _ = try p1.wait();

    var p2 = std.ChildProcess.init(&.{ "stty", "-F", "/dev/tty", "-echo" }, std.heap.page_allocator);
    try p2.spawn();
    _ = try p2.wait();
}

// TODO: add windows
fn getColumns() !u16 {
    var win: std.os.linux.winsize = undefined;
    if (std.os.linux.ioctl(std.os.linux.STDOUT_FILENO, std.os.linux.T.IOCGWINSZ, @intFromPtr(&win)) == -1) {
        return error.GetWinSize;
    }
    return win.ws_col;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    try stty();

    const stdout_file = std.io.getStdOut();
    const stdin_file = std.io.getStdIn();

    var bw = std.io.bufferedWriter(stdout_file.writer());
    const stdout = bw.writer();

    //try stdout.writeAll("\x1B[?25l");
    try color.translate(stdout, "&42&30 panda &0 Panda 3000 launched.\n\n");
    try color.translate(stdout, "  &45&97 name &0  What is your name?\n"); //        &2write a number" ++ cursor.save ++ "  &91▶ Directory is not empty!" ++ cursor.restore);

    var input = std.ArrayList(u8).init(allocator);
    defer input.deinit();

    while (true) {
        const prefix = "          ";
        try stdout.print("\x1B[1G" ++ prefix ++ "{s}", .{input.items});
        try bw.flush();

        const c = try stdin_file.reader().readByte();
        const i = (input.items.len + prefix.len - 1) / try getColumns();

        switch (c) {
            '\x1B' => {
                // idk what todo here prob if we get in stdin more then one char we will return.
            },
            '\x7F' => if (input.items.len > 0) {
                _ = input.pop();
            },
            else => if (isToken(c)) {
                try input.append(c);
            },
        }
        try stdout.writeAll("\x1B[2K");
        if (i > 0) try stdout.print("\x1B[{d}A", .{i});
    }
}

test {
    std.testing.refAllDecls(@This());
}
