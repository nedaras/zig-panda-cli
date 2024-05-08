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

pub fn count(comptime str: []const u8) usize {
    var counting_writer = std.io.countingWriter(std.io.null_writer);
    translate(counting_writer.writer().any(), str) catch unreachable;
    return counting_writer.bytes_written;
}

pub fn translate(writer: anytype, comptime str: []const u8) !void {
    // TODO: check if its color code after color code thn just add ;
    @setEvalBranchQuota(2000000);
    comptime var i = 0;
    comptime var last_reset = false;
    inline while (i < str.len) : (i += 1) {
        if (str[i] == '&') {
            if (i + 1 >= str.len) @compileError("missing color code");

            last_reset = false;
            switch (str[i + 1]) {
                '0' => try writer.writeAll(black),
                '1' => try writer.writeAll(dark_blue),
                '2' => try writer.writeAll(dark_green),
                '3' => try writer.writeAll(dark_aqua),
                '4' => try writer.writeAll(dark_red),
                '5' => try writer.writeAll(dark_purple),
                '6' => try writer.writeAll(gold),
                '7' => try writer.writeAll(gray),
                '8' => try writer.writeAll(dark_gray),
                '9' => try writer.writeAll(blue),
                'a' => try writer.writeAll(green),
                'b' => try writer.writeAll(aqua),
                'c' => try writer.writeAll(red),
                'd' => try writer.writeAll(light_purple),
                'e' => try writer.writeAll(yellow),
                'f' => try writer.writeAll(white),
                'k' => try writer.writeAll(blink),
                'l' => try writer.writeAll(bold),
                'm' => try writer.writeAll(strikethrough),
                'n' => try writer.writeAll(underline),
                'o' => try writer.writeAll(italic),
                'r' => {
                    try writer.writeAll(reset);
                    last_reset = true;
                },
                else => @compileError(std.fmt.comptimePrint("no color with code '{c}'", .{str[i + 1]})),
            }
            i += 1;
            continue;
        }
        try writer.writeByte(str[i]);
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
