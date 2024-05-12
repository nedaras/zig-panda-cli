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

const PromtOptions = struct {
    name: []const u8,
    message: []const u8,
    placeholder: ?[]const u8 = null,
    //verify: fn ([]const u8) ?[]const u8,
};

fn promt(allocator: std.mem.Allocator, options: PromtOptions) !f64 {
    const stdout_file = std.io.getStdOut();
    const stdin_file = std.io.getStdIn();

    var bw = std.io.bufferedWriter(stdout_file.writer());
    const stdout = bw.writer();

    const name = comptime color.comptimeTranslate("   &45&97 ");
    const reset = comptime color.comptimeTranslate(" &0  ");
    // TODO: add comptime strip
    const prefix_len = 3 + 1 + options.name.len + 1 + 2;

    try stdout.print("\n" ++ name ++ "{s}" ++ reset ++ "{s}\n", .{ options.name, options.message });

    var input = std.ArrayList(u8).init(allocator);
    defer input.deinit();

    while (true) {
        try stdout.writeAll("\x1B[1G");
        try stdout.writeByteNTimes(' ', prefix_len);

        if (input.items.len > 0)
            try stdout.writeAll(input.items)
        else if (options.placeholder) |placeholder|
            try stdout.print(color.dim ++ "{s}" ++ color.reset, .{placeholder});

        try bw.flush();

        const c = try stdin_file.reader().readByte();

        const input_len = if (input.items.len > 0) input.items.len else if (options.placeholder) |p| p.len else 0;
        const i = (input_len + prefix_len - 1) / try getColumns();

        switch (c) {
            '\x1B' => {
                // idk what todo here prob if we get in stdin more then one char we will return.
            },
            '\x7F' => if (input.items.len > 0) {
                _ = input.pop();
            },
            '\n' => {
                try stdout.writeByte('\n');
                try bw.flush();
                return 69;
            },
            else => if (isToken(c)) {
                try input.append(c);
            },
        }
        try stdout.writeAll("\x1B[2K");
        if (i > 0) try stdout.print("\x1B[{d}A", .{i});

        try bw.flush();
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    //try stdout.writeAll("\x1B[?25l");
    try stty();

    const stdout_file = std.io.getStdOut();

    var bw = std.io.bufferedWriter(stdout_file.writer());
    const stdout = bw.writer();

    try color.translate(stdout, "\n&42&30 panda &0 Calculator launched.\n");
    //try color.translate(stdout, "  &45&97 name &0  What is your name?\n"); //        &2write a number" ++ cursor.save ++ "  &91▶ Directory is not empty!" ++ cursor.restore);

    try bw.flush();
    _ = try promt(allocator, .{
        .name = "kg",
        .message = "What is your haul's weight?",
    });
}

test {
    std.testing.refAllDecls(@This());
}
