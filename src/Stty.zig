const std = @import("std");
const Allocator = std.mem.Allocator;

const Self = @This();

allocator: Allocator,
cmd: [2][]const u8,

pub fn init(allocator: Allocator) !Self {
    var child = std.ChildProcess.init(&.{ "stty", "-g" }, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    var stdout = std.ArrayList(u8).init(allocator);
    var stderr = std.ArrayList(u8).init(allocator);

    defer {
        stdout.deinit();
        stderr.deinit();
    }

    try child.spawn();
    try child.collectOutput(&stdout, &stderr, 1024);

    _ = try child.wait();
    _ = stdout.pop();

    var cmd: [2][]const u8 = undefined;
    cmd[0] = "stty";
    cmd[1] = try stdout.toOwnedSlice();

    var a = std.ChildProcess.init(&.{ "stty", "-F", "/dev/tty", "cbreak", "min", "1" }, allocator);
    _ = try a.spawnAndWait();

    var b = std.ChildProcess.init(&.{ "stty", "-F", "/dev/tty", "-echo" }, allocator);
    _ = try b.spawnAndWait();

    return .{
        .allocator = allocator,
        .cmd = cmd,
    };
}

pub fn deinit(self: Self) void {
    var child = std.ChildProcess.init(&self.cmd, self.allocator);
    _ = child.spawnAndWait() catch unreachable;

    self.allocator.free(self.cmd[1]);
}
