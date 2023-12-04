const std = @import("std");

const MAX_CARD_NUM = 203;
const BUFF_SIZE = 1024 * 100;

inline fn charPairToInt(pair: *const [2]u8) u8 {
    return if (pair[0] != ' ') (pair[0] - '0') * 10 + (pair[1] - '0') else pair[1] - '0';
}

const number_iterator = struct {
    input: []const u8,

    fn next(self: *number_iterator) ?*const [2]u8 {
        if (self.input.len < 3) {
            return null;
        }

        const digits = self.input[1..3];
        self.input = self.input[3..];
        return digits;
    }

    fn remaining(self: number_iterator) usize {
        return self.input.len / 3;
    }
};

pub fn main() !void {
    var args = std.process.args();

    const program_name = args.next().?;
    const file_name = args.next();

    if (file_name == null) {
        std.debug.print("Usage: {s} <file>\n", .{program_name});
        std.process.exit(1);
    }

    const file = try std.fs.cwd().openFile(file_name.?, .{});
    var reader = file.reader();

    var buff: [BUFF_SIZE]u8 = undefined;
    var n = try reader.readAll(&buff);

    var lines = std.mem.splitScalar(u8, buff[0..n], '\n');
    const offset = std.mem.indexOfScalar(u8, buff[0..n], ':').? + 1;

    var total_points: usize = 0;

    var card_growth: [MAX_CARD_NUM]u32 = undefined;

    for (0..card_growth.len) |i| {
        card_growth[i] = 0;
    }

    var card_number: usize = 0;

    while (lines.next()) |line| {
        const current_growth = card_growth[card_number] + 1;

        var lists = std.mem.splitScalar(u8, line[offset..], '|');

        var winning_list_input = lists.next() orelse unreachable;
        winning_list_input = winning_list_input[0 .. winning_list_input.len - 1];

        const owned_list_input = lists.next() orelse unreachable;

        var owned_iterator = number_iterator{ .input = owned_list_input };
        var winning_iterator = number_iterator{ .input = winning_list_input };
        var i: u6 = 0;
        var winning_check_list: [100]bool = undefined;

        while (winning_iterator.next()) |num2| {
            winning_check_list[charPairToInt(num2)] = true;
        }

        while (owned_iterator.next()) |num| {
            if (winning_check_list[charPairToInt(num)] == true) {
                i += 1;
            }
        }

        if (i > 0) {
            for (1..(i + 1)) |j| {
                card_growth[card_number + j] += current_growth;
            }
            total_points += @as(u64, 1) << (i - 1);
        }

        card_growth[card_number] = current_growth;
        card_number += 1;
    }

    var sum: u32 = 0;

    for (card_growth) |x| {
        if (x == 0) break;
        sum += x;
    }

    std.debug.print("{d}\n", .{total_points});
    std.debug.print("{d}\n", .{sum});
}
