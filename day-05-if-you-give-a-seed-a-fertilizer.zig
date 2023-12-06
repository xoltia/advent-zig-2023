const std = @import("std");

const MAX_FILE_SIZE = 1024 * 1024;

const map_entry = struct {
    lower_value: usize,
    lower_key: usize,
    upper_key: usize,

    fn getValue(self: map_entry, key: usize) ?usize {
        if (key < self.lower_key or key > self.upper_key) {
            return null;
        }

        return self.lower_value + (key - self.lower_key);
    }
};

fn readMapEntry(input: []const u8) !map_entry {
    var nums = std.mem.splitScalar(u8, input, ' ');
    const value = try std.fmt.parseUnsigned(usize, nums.next().?, 10);
    const lower_key = try std.fmt.parseUnsigned(usize, nums.next().?, 10);
    const r = try std.fmt.parseUnsigned(usize, nums.next().?, 10);

    return map_entry{
        .lower_value = value,
        .lower_key = lower_key,
        .upper_key = lower_key + (r - 1),
    };
}

fn swapKeysForValues(map: []const u8, keys: *std.ArrayList(usize)) !void {
    var lines = std.mem.splitScalar(u8, map, '\n');
    var values = try keys.clone();
    defer values.deinit();
    var found: usize = 0;

    while (lines.next()) |line| {
        if (found == keys.items.len) {
            break;
        }

        const entry = try readMapEntry(line);

        for (keys.items, 0..) |key, i| {
            if (entry.getValue(key)) |value| {
                values.items[i] = value;
                found += 1;
            }
        }
    }

    try keys.replaceRange(0, keys.items.len, values.items);
}

const intersection_result = struct {
    matched: ?range,
    unmatched_lower: ?range,
    unmatched_upper: ?range,
};

const range = struct {
    lower: usize,
    upper: usize,

    fn newFromLength(lower: usize, length: usize) range {
        return range{
            .lower = lower,
            .upper = lower + (length - 1),
        };
    }

    fn intersect(self: range, other: range) intersection_result {
        if (other.lower > self.upper or other.upper < self.lower) {
            return intersection_result{
                .matched = null,
                .unmatched_lower = self,
                .unmatched_upper = null,
            };
        }

        var matched = range{
            .lower = @max(self.lower, other.lower),
            .upper = @min(self.upper, other.upper),
        };

        var unmatched_lower: ?range = null;
        var unmatched_upper: ?range = null;

        if (matched.lower > self.lower) {
            unmatched_lower = range{
                .lower = self.lower,
                .upper = matched.lower - 1,
            };
        }

        if (matched.upper < self.upper) {
            unmatched_upper = range{
                .lower = matched.upper + 1,
                .upper = self.upper,
            };
        }

        return intersection_result{
            .matched = matched,
            .unmatched_lower = unmatched_lower,
            .unmatched_upper = unmatched_upper,
        };
    }

    fn getSubrangeOffset(self: range, other: range) ?range {
        if (other.lower < self.lower or other.upper > self.upper) {
            return null;
        }

        return range{
            .lower = other.lower - self.lower,
            .upper = other.upper - self.lower,
        };
    }

    fn fromScalarAndRange(scalar: usize, r: range) range {
        return range{
            .lower = scalar + r.lower,
            .upper = scalar + r.upper,
        };
    }
};

fn getKeyRangesForValueRanges(map: []const u8, key_ranges: *std.ArrayList(range)) !std.ArrayList(range) {
    var lines = std.mem.splitScalar(u8, map, '\n');
    var value_ranges = std.ArrayList(range).init(key_ranges.allocator);
    defer value_ranges.deinit();

    while (lines.next()) |line| {
        const entry = try readMapEntry(line);
        const value = entry.lower_value;
        const key_range = range{ .lower = entry.lower_key, .upper = entry.upper_key };

        var len = key_ranges.items.len;
        var i: usize = 0;

        while (i < len) : (i += 1) {
            const check_range = key_ranges.items[i];
            const result = check_range.intersect(key_range);

            if (result.matched) |matched| {
                const key_offset_range = key_range.getSubrangeOffset(matched);
                const value_range = range.fromScalarAndRange(value, key_offset_range.?);
                try value_ranges.append(value_range);
            }

            if (result.unmatched_lower) |unmatched_lower| {
                try key_ranges.append(unmatched_lower);
            }

            if (result.unmatched_upper) |unmatched_upper| {
                try key_ranges.append(unmatched_upper);
            }
        }

        for (key_ranges.items[len..], 0..) |new_key_range, j| {
            key_ranges.items[j] = new_key_range;
        }

        try key_ranges.resize(key_ranges.items.len - len);
    }

    try key_ranges.appendSlice(value_ranges.items);
    return key_ranges.*;
}

const offsets = [_]comptime_int{
    "seed-to-soil map:\n".len,
    "soil-to-fertilizer map:\n".len,
    "fertilizer-to-water map:\n".len,
    "water-to-light map:\n".len,
    "light-to-temperature map:\n".len,
    "temperature-to-humidity map:\n".len,
    "humidity-to-location map:\n".len,
};

fn part1(allocator: std.mem.Allocator, input: []u8) !void {
    var sections = std.mem.splitSequence(u8, input, "\n\n");
    var seeds = std.mem.splitScalar(u8, sections.next().?[7..], ' ');
    var seed_numbers = std.ArrayList(usize).init(allocator);
    defer seed_numbers.deinit();

    while (seeds.next()) |seed| {
        const number = try std.fmt.parseUnsigned(usize, seed, 10);
        try seed_numbers.append(number);
    }

    inline for (offsets) |offset| {
        try swapKeysForValues(sections.next().?[offset..], &seed_numbers);
    }

    const min = std.mem.min(usize, seed_numbers.items);
    std.debug.print("Lowest location: {d}\n", .{min});
}

fn part2(allocator: std.mem.Allocator, input: []u8) !void {
    var sections = std.mem.splitSequence(u8, input, "\n\n");
    var seeds = std.mem.splitScalar(u8, sections.next().?[7..], ' ');
    var seed_ranges = std.ArrayList(range).init(allocator);

    while (seeds.next()) |seed| {
        const number = try std.fmt.parseUnsigned(usize, seed, 10);
        const length = try std.fmt.parseUnsigned(usize, seeds.next().?, 10);
        try seed_ranges.append(range.newFromLength(number, length));
    }

    inline for (offsets) |offset| {
        seed_ranges = try getKeyRangesForValueRanges(sections.next().?[offset..], &seed_ranges);
    }

    var min: usize = std.math.maxInt(usize);

    for (seed_ranges.items) |r| {
        if (r.lower < min) {
            min = r.lower;
        }
    }

    seed_ranges.deinit();

    std.debug.print("Lowest location: {d}\n", .{min});
}

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

    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    var allocator = gpa.allocator();

    const input = try reader.readAllAlloc(allocator, MAX_FILE_SIZE);

    try part1(allocator, input);
    try part2(allocator, input);
}
