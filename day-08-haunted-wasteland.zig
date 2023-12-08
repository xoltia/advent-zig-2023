const std = @import("std");

const BUFF_SIZE = 1024 * 200;

pub fn main() !void {
    var args = std.process.args();
    _ = args.next() orelse unreachable;

    const file = if (args.next()) |file_name|
        try std.fs.cwd().openFile(file_name, .{})
    else
        std.io.getStdIn();

    defer file.close();

    var buff: [BUFF_SIZE]u8 = undefined;
    const n = try file.readAll(&buff);
    const file_contents = buff[0..n];

    var lines = std.mem.splitScalar(u8, file_contents, '\n');
    const directions = lines.next() orelse unreachable;

    var fba = std.heap.FixedBufferAllocator.init(buff[n..]);
    const allocator = fba.allocator();
    var nodes = std.StringHashMap(struct { left: *const [3]u8, right: *const [3]u8 }).init(allocator);
    defer nodes.deinit();

    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        const key = line[0..3];
        const l_offset: comptime_int = "AAA = (".len;
        const r_offset: comptime_int = "AAA = (BBB, ".len;
        const left = line[l_offset .. l_offset + 3];
        const right = line[r_offset .. r_offset + 3];
        try nodes.put(key, .{ .left = left, .right = right });
    }

    var current_key: *const [3]u8 = "AAA";
    var hops: usize = 0;

    while (!std.mem.eql(u8, current_key, "ZZZ")) : (hops += 1) {
        current_key = switch (directions[@mod(hops, directions.len)]) {
            'L' => nodes.get(current_key).?.left,
            'R' => nodes.get(current_key).?.right,
            else => unreachable,
        };
    }

    std.debug.print("{d}\n", .{hops});
}
