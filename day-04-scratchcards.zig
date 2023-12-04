const std = @import("std");

const number_iterator = struct {
    input: []const u8,

    fn collect(self: *number_iterator, allocator: std.mem.Allocator) !std.ArrayList(*const [2]u8) {
        var list = try std
            .ArrayList(*const [2]u8)
            .initCapacity(allocator, self.remaining());

        while (self.next()) |digits| {
            try list.append(digits);
        }

        return list;
    }

    fn next(self: *number_iterator) ?*const [2]u8 {
        if (self.input.len < 4) {
            return null;
        }

        const digits = self.input[1..3];
        // var result: u8 = if (digits[0] != ' ') (digits[0] - '0') * 10 else 0;
        // result += digits[1] - '0';
        self.input = self.input[3..];
        return digits;
    }

    fn remaining(self: number_iterator) usize {
        return (self.input.len - 1) / 3;
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var args = try std.process.argsWithAllocator(allocator);

    const program_name = args.next().?;
    const file_name = args.next();

    if (file_name == null) {
        std.debug.print("Usage: {s} <file>\n", .{program_name});
        std.process.exit(1);
    }

    const file = try std.fs.cwd().openFile(file_name.?, .{});
    const reader = file.reader();

    const offset = 9;
    var total_points: usize = 0;

    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        defer allocator.free(line);

        var lists = std.mem.splitScalar(u8, line[offset..], '|');
        const winning_list_input = lists.next() orelse unreachable;

        var winning_iterator = number_iterator{ .input = winning_list_input };
        const winning_list = try winning_iterator.collect(allocator);
        defer winning_list.deinit();

        const owned_list_input = lists.next() orelse unreachable;
        var owned_iterator = number_iterator{ .input = owned_list_input };
        var i: u6 = 0;

        while (owned_iterator.next()) |num| {
            for (winning_list.items) |num2| {
                if (std.mem.eql(u8, num, num2)) {
                    i += 1;
                }
            }
        }

        total_points += if (i == 0) 0 else @as(u64, 1) << (i - 1);
    }

    std.debug.print("{d}\n", .{total_points});
}
