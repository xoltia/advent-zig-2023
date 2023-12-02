const std = @import("std");

fn getDigitValueFromWordWindow(window: []const u8, fromBack: bool) ?usize {
    const words = [10][]const u8{
        "zero",
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine",
    };

    for (words, 0..) |word, i| {
        const windowMax = if (word.len > window.len) window.len else word.len;
        const shrunkWindow = if (fromBack) window[window.len - windowMax ..] else window[0..windowMax];

        if (std.mem.eql(u8, word, shrunkWindow)) {
            return i;
        }
    }

    return null;
}

pub fn main() !void {
    var file = std.io.getStdIn();
    var args = std.process.args();

    _ = args.skip();

    if (args.next()) |fileName| {
        file = try std.fs.cwd().openFile(fileName, .{});
    }

    defer file.close();

    const allocator = std.heap.page_allocator;
    var reader = file.reader();
    var total: usize = 0;

    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        for (line, 0..) |c, i| {
            switch (c) {
                '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
                    total += (c - '0') * 10;
                    break;
                },
                else => {
                    var digit = getDigitValueFromWordWindow(line[i..], false);
                    if (digit != null) {
                        total += digit.? * 10;
                        break;
                    }
                },
            }
        }

        var i = line.len - 1;

        while (i > 0) : (i -= 1) {
            switch (line[i]) {
                '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
                    total += (line[i] - '0');
                    break;
                },
                else => {
                    var digit = getDigitValueFromWordWindow(line[0 .. i + 1], true);
                    if (digit != null) {
                        total += digit.?;
                        break;
                    }
                },
            }
        }

        if (i == 0) {
            total += (line[i] - '0');
        }

        allocator.free(line);
    }

    std.debug.print("Total: {}\n", .{total});
}
