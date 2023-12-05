const std = @import("std");

const MAX_FILE_SIZE = 1024 * 1024;

const map_entry = struct {
    lower_value: usize,
    lower_key: usize,
    upper_key: usize,

    fn get_value(self: map_entry, key: usize) ?usize {
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
    const range = try std.fmt.parseUnsigned(usize, nums.next().?, 10);

    return map_entry{
        .lower_value = value,
        .lower_key = lower_key,
        .upper_key = lower_key + (range - 1),
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
            if (entry.get_value(key)) |value| {
                values.items[i] = value;
                found += 1;
            }
        }
    }

    try keys.replaceRange(0, keys.items.len, values.items);
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

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    const input = try reader.readAllAlloc(allocator, MAX_FILE_SIZE);
    var sections = std.mem.splitSequence(u8, input, "\n\n");
    var seeds = std.mem.splitScalar(u8, sections.next().?[7..], ' ');
    var seedNumbers = std.ArrayList(usize).init(allocator);
    defer seedNumbers.deinit();

    while (seeds.next()) |seed| {
        const number = try std.fmt.parseUnsigned(usize, seed, 10);
        try seedNumbers.append(number);
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

    inline for (offsets) |offset| {
        try swapKeysForValues(sections.next().?[offset..], &seedNumbers);
    }

    const min = std.mem.min(usize, seedNumbers.items);
    std.debug.print("Lowest location: {d}\n", .{min});
}
