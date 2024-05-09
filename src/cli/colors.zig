const std = @import("std");

pub const black = "\x1b[30m";
pub const dark_blue = "\x1b[34m";
pub const dark_green = "\x1b[32m";
pub const dark_aqua = "\x1b[36m";
pub const dark_red = "\x1b[31m";
pub const dark_purple = "\x1b[35m";
pub const gold = "\x1b[33m";
pub const gray = "\x1b[37m";
pub const dark_gray = "\x1b[90m";
pub const blue = "\x1b[94m";
pub const green = "\x1b[92m";
pub const aqua = "\x1b[96m";
pub const red = "\x1b[91m";
pub const light_purple = "\x1b[95m";
pub const yellow = "\x1b[93m";
pub const white = "\x1b[97m";
pub const blink = "\x1b[5m";
pub const bold = "\x1b[1m";
pub const strikethrough = "\x1b[9m";
pub const underline = "\x1b[4m";
pub const italic = "\x1b[3m";
pub const reset = "\x1b[0m";

pub const black_bg = "\x1b[40m";
pub const dark_blue_bg = "\x1b[44m";
pub const dark_green_bg = "\x1b[42m";
pub const dark_aqua_bg = "\x1b[46m";
pub const dark_red_bg = "\x1b[41m";
pub const dark_purple_bg = "\x1b[45m";
pub const gold_bg = "\x1b[43m";
pub const gray_bg = "\x1b[47m";
pub const dark_gray_bg = "\x1b[100m";
pub const blue_bg = "\x1b[104m";
pub const green_bg = "\x1b[102m";
pub const aqua_bg = "\x1b[106m";
pub const red_bg = "\x1b[101m";
pub const light_purple_bg = "\x1b[105m";
pub const yellow_bg = "\x1b[103m";
pub const white_bg = "\x1b[107m";

pub fn count(comptime str: []const u8) usize {
    var counting_writer = std.io.countingWriter(std.io.null_writer);
    translate(counting_writer.writer().any(), str) catch unreachable;
    return counting_writer.bytes_written;
}

pub fn translate(writer: anytype, comptime str: []const u8) !void {
    @setEvalBranchQuota(2000000);
    comptime var i = 0;
    comptime var last_reset = false;
    inline while (i < str.len) {
        const start_index = i;
        inline while (i < str.len) : (i += 1) {
            switch (str[i]) {
                '&' => break,
                else => {},
            }
        }
        const end_index = i;

        if (start_index != end_index) {
            try writer.writeAll(str[start_index..end_index]);
        }

        if (i >= str.len) break;

        last_reset = false;
        i += 1;

        const color_begin = i;
        inline while (i < str.len) : (i += 1) {
            if (str[i] < '0' or str[i] > '9') break;
        }
        const color_end = i;

        if (color_begin == color_end) {
            @compileError("missing or invalid color code");
        }

        try writer.print("\x1B[{s}m", .{str[color_begin..color_end]});
        last_reset = std.mem.eql(u8, str[color_begin..color_end], "0");
    }
    if (!last_reset) {
        try writer.writeAll(reset);
    }
}

pub fn bufTranslate(buf: []u8, comptime str: []const u8) ![]u8 {
    var fbs = std.io.fixedBufferStream(buf);
    try translate(fbs.writer().any(), str);
    return fbs.getWritten();
}

pub fn comptimeTranslate(comptime str: []const u8) *const [count(str):0]u8 {
    comptime {
        var buf: [count(str):0]u8 = undefined;
        _ = bufTranslate(&buf, str) catch unreachable;
        buf[buf.len] = 0;
        const final = buf;
        return &final;
    }
}

pub fn stdoutPrint(comptime fmt: []const u8, args: anytype) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print(comptimeTranslate(fmt), args);
}
