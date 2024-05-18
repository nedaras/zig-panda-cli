const std = @import("std");
const Allocator = std.mem.Allocator;
const color = @import("cli/colors.zig");
const cursor = @import("cli/cursor.zig");

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
    verify: *const fn (input: []const u8) ?[]const u8,
};

pub fn getOutput(allocator: Allocator, options: PromtOptions) ![]u8 {
    const stdout_file = std.io.getStdOut();
    const stdin_file = std.io.getStdIn();

    var bw = std.io.bufferedWriter(stdout_file.writer());
    const stdout = bw.writer();

    const name = comptime color.comptimeTranslate("&45&97 ");
    const reset = comptime color.comptimeTranslate(" &0  ");
    // TODO: add comptime strip
    const prefix_len = (6 - options.name.len) + 1 + options.name.len + 1 + 2;

    try stdout.writeByte('\n');
    try stdout.writeByteNTimes(' ', 6 - options.name.len);
    try stdout.print(name ++ "{s}" ++ reset ++ "{s}\n", .{ options.name, options.message });

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
                // todo dim result after enter
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
