const std = @import("std");
const cursor = @import("cli/cursor.zig");
const color = @import("cli/colors.zig");
const Regex = @import("Regex.zig");
const Stty = @import("Stty.zig");
const promt = @import("promt.zig");

// never return allocated strings
// mb add cleanup function or with typeinfo check if string needs to be freeded.
fn verifyFloat(input: []const u8) ?[]const u8 {
    if (input.len == 0) return "";
    _ = std.fmt.parseFloat(f64, input) catch return "Weight has to be a number!";
    return null;
}

fn verifyInteger(input: []const u8) ?[]const u8 {
    // todo: make it more logical like throw error if negatice number
    if (input.len == 0) return "";
    _ = std.fmt.parseInt(u32, input, 10) catch return "it has to be a fixed number!";
    return null;
}

// TODO: make make it in grams
fn getWeight(allocator: std.mem.Allocator, user: u32) !u32 {
    const name = try std.fmt.allocPrint(allocator, "#{d}", .{user});
    defer allocator.free(name);

    const out = try promt.getOutput(allocator, .{ .name = name, .message = "how much weigth is user contributing?", .verify = verifyInteger, .placeholder = "./grams" });
    defer allocator.free(out);
    return std.fmt.parseUnsigned(u32, out, 10) catch unreachable;
}

fn getShippingPrice(allocator: std.mem.Allocator) !f64 {
    const out = try promt.getOutput(allocator, .{ .name = "eur", .message = "what is your haul's shipping price?", .verify = verifyFloat });
    defer allocator.free(out);
    return std.fmt.parseFloat(f64, out) catch unreachable;
}

fn getUsers(allocator: std.mem.Allocator) !std.meta.Tuple(&.{ u32, []u32 }) {
    const out = try promt.getOutput(allocator, .{ .name = "users", .message = "How many peaple are contributing?", .verify = verifyInteger });
    defer allocator.free(out);

    const users = try allocator.alloc(u32, std.fmt.parseUnsigned(u32, out, 10) catch unreachable);
    var total_weigth: u32 = 0;

    for (0..users.len) |user| {
        const weigth = try getWeight(allocator, @intCast(user + 1));

        users[user] = weigth;
        total_weigth += weigth;
    }
    return .{ total_weigth, users };
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

    // hoobuy is a scam btw
    try color.translate(stdout, "\n&42&30 hoobuy &0  Calculator launched.\n");
    try bw.flush();

    const tuple = try getUsers(allocator);
    defer allocator.free(tuple[1]);

    const total_weigth = tuple[0];
    const users_weigths = tuple[1];

    try stdout.print(color.comptimeTranslate("\n&42&30 hoobuy &0  Total hauls weigth is {d:.1}kg.\n"), .{@as(f64, @floatFromInt(total_weigth)) / 1000.0});
    try bw.flush();

    const price = try getShippingPrice(allocator);
    const ratio = price / @as(f64, @floatFromInt(total_weigth));

    try color.translate(stdout, "\n&42&30 hoobuy &0  Done...\n\n");
    for (0.., users_weigths) |i, user| {
        try stdout.print(color.comptimeTranslate("          &32●&0 User #{d} fee - {d:.2}$.\n"), .{ i, @as(f64, @floatFromInt(user)) * ratio });
    }
    try stdout.writeByte('\n');
    try bw.flush();
}

test {
    std.testing.refAllDecls(@This());
}
