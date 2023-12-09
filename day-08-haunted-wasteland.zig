const std = @import("std");

const BUFF_SIZE = 1024 * 200;
const MAX_FILE_SIZE = 1024 * 100;

fn gcd(comptime T: type, a: T, b: T) T {
    return if (b == 0)
        a
    else
        gcd(T, b, a % b);
}

inline fn lcm(comptime T: type, a: T, b: T) T {
    return (a * b) / gcd(T, a, b);
}

fn part1(file_contents: []u8, allocator: std.mem.Allocator) !usize {
    var lines = std.mem.splitScalar(u8, file_contents, '\n');
    const directions = lines.next() orelse unreachable;
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

    return hops;
}

fn part2(file_contents: []u8, allocator: std.mem.Allocator) !usize {
    var lines = std.mem.splitScalar(u8, file_contents, '\n');
    const directions = lines.next() orelse unreachable;
    var nodes = std.StringArrayHashMap(struct { left: *const [3]u8, right: *const [3]u8 }).init(allocator);
    var starting_keys = std.ArrayList(*const [3]u8).init(allocator);
    defer nodes.deinit();
    defer starting_keys.deinit();

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

        if (key[2] == 'A') {
            try starting_keys.append(key);
        }
    }

    var overall_lcm: usize = 1;

    for (starting_keys.items) |current_key| {
        var hops: usize = 0;
        var new_key = current_key;

        while (new_key[2] != 'Z') : (hops += 1) {
            while (std.mem.eql(u8, new_key, "XXX")) {
                const idx = nodes.getIndex(current_key).?;
                new_key = nodes.unmanaged.entries.get(idx + 1).key[0..3];
            }

            new_key = switch (directions[@mod(hops, directions.len)]) {
                'L' => nodes.get(new_key).?.left,
                'R' => nodes.get(new_key).?.right,
                else => unreachable,
            };
        }

        overall_lcm = lcm(usize, overall_lcm, hops);
    }

    return overall_lcm;
}

pub fn main() !void {
    var args = std.process.args();
    _ = args.next() orelse unreachable;

    const file = if (args.next()) |file_name|
        try std.fs.cwd().openFile(file_name, .{})
    else
        std.io.getStdIn();

    defer file.close();

    var buff: [BUFF_SIZE]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buff);
    const allocator = fba.allocator();
    const file_contents = try file.readToEndAlloc(allocator, MAX_FILE_SIZE);
    defer allocator.free(file_contents);
    const hops_part1 = try part1(file_contents, allocator);
    const hops_part2 = try part2(file_contents, allocator);

    std.debug.print("P1: {}\n", .{hops_part1});
    std.debug.print("P2: {}\n", .{hops_part2});
}
