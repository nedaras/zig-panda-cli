const std = @import("std");
const cursor = @import("cli/cursor.zig");
const color = @import("cli/colors.zig");
const Regex = @import("Regex.zig");
const Stty = @import("Stty.zig");

fn isToken(c: u8) bool {
    return c > 31 and c < 127;
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
    verify: fn ([]const u8) ?[]const u8,
};

fn promt(allocator: std.mem.Allocator, options: PromtOptions) ![]u8 {
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

        var err = false;
        if (options.verify(input.items)) |out| {
            if (out.len > 0) try stdout.print(cursor.save ++ "  " ++ color.red ++ "▶ {s}" ++ cursor.restore, .{out});
            err = true;
        }

        try bw.flush();

        const c = try stdin_file.reader().readByte();

        const input_len = if (input.items.len > 0) input.items.len else if (options.placeholder) |p| p.len else 0;
        const i = (input_len + prefix_len - 1) / try getColumns();

        switch (c) {
            '\x1B' => {
                // idk what todo here prob if we get in stdin more then one char we will return. but ctrl-v will be canceled.
            },
            '\x7F' => if (input.items.len > 0) {
                _ = input.pop();
            },
            '\n' => if (!err) {
                try stdout.writeByte('\n');
                try bw.flush();
                return input.toOwnedSlice();
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

// never return allocated strings
// mb add cleanup function or with typeinfo check if string needs to be freeded.
fn verify(input: []const u8) ?[]const u8 {
    if (input.len == 0) return "";
    _ = std.fmt.parseFloat(f64, input) catch return "Weight has to be a number!";
    return null;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    //try stdout.writeAll("\x1B[?25l");
    const stty = try Stty.init(allocator);
    defer stty.deinit();

    const stdout_file = std.io.getStdOut();

    var bw = std.io.bufferedWriter(stdout_file.writer());
    const stdout = bw.writer();

    try color.translate(stdout, "\n&42&30 panda &0 Calculator launched.\n");
    try bw.flush();

    const out = try promt(allocator, .{ .name = "kg", .message = "What is your haul's weight?", .verify = verify });
    defer allocator.free(out);

    const weight = std.fmt.parseFloat(f64, out) catch unreachable;
    std.debug.print("ya weight is: {d}kg\n", .{weight});
}

test {
    std.testing.refAllDecls(@This());
}
