const std = @import("std");
const colors = @import("cli/colors.zig");

pub fn getNumber() !f64 {
    var buf: [16]u8 = undefined;
    const stdin = std.io.getStdIn().reader();

    try colors.stdoutPrint("&aEnter a number: ", .{});

    while (true) {
        const a = stdin.readUntilDelimiter(&buf, '\n') catch |err| switch (err) {
            error.StreamTooLong => {
                try colors.stdoutPrint("&cYo yo shit is too long!\n", .{});

                // we need to read whole in buffer
                var writer = std.io.countingWriter(std.io.null_writer);
                stdin.streamUntilDelimiter(writer.writer().any(), '\n', null) catch unreachable;

                continue;
            },
            else => {
                std.debug.panic("err: {}", .{err});
                continue;
            },
        };

        return std.fmt.parseFloat(f64, a) catch {
            try colors.stdoutPrint("&cit aint a number!\n", .{});
            continue;
        };
    }
}

pub fn getFunction() ![2]f64 {
    var out: [2]f64 = undefined;
    out[0] = 1.29;
    out[1] = 0.5;

    _ = try getNumber();

    return out;
}

pub fn main() !void {
    const f = try getFunction();
    try colors.stdoutPrint("&af(x) = {d}x + {d}\n", .{ f[0], f[1] });

    //const slope = (y1.? - y2.?) / (x1.? - x2.?);
    //const c = y1.? - slope * x1.?;

    //std.debug.print(colors.comptimeTranslate("f(x) = {d}x + {d}\n"), .{ slope, c });

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
