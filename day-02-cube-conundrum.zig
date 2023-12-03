const std = @import("std");

fn skipWhitespace(str: []const u8) usize {
    var n: usize = 0;
    while (n < str.len) : (n += 1) {
        if (std.ascii.isWhitespace(str[n])) continue;
        break;
    }
    return n;
}

fn readNumber(comptime T: type, str: []const u8, out: *T) !usize {
    var n: T = 0;
    while (n < str.len) : (n += 1) {
        if (std.ascii.isDigit(str[n])) continue;
        break;
    }
    if (n == 0) return 0;
    out.* = try std.fmt.parseUnsigned(T, str[0..n], 10);
    return n;
}

fn readAlphabetic(str: []const u8) ([]const u8) {
    var i: usize = 0;
    while (i < str.len) : (i += 1) {
        if (std.ascii.isAlphabetic(str[i])) continue;
        break;
    }
    return str[0..i];
}

pub fn main() !void {
    var reader = std.io.getStdIn().reader();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    var allocator = gpa.allocator();
    var total: usize = 0;
    var totalPower: usize = 0;

    while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        defer allocator.free(line);

        if (line.len < 6) {
            continue;
        }

        var i = try (std.ascii.indexOfIgnoreCase(line[5..], ":") orelse error.ColonNotFound);
        const id = try std.fmt.parseUnsigned(usize, line[5..(5 + i)], 10);
        i += 6;
        var valid = true;
        var maxRed: usize = 0;
        var maxGreen: usize = 0;
        var maxBlue: usize = 0;

        while (i < line.len) {
            var red: usize = 0;
            var green: usize = 0;
            var blue: usize = 0;

            while (i < line.len) : (i += 1) {
                i += skipWhitespace(line[i..]);
                var x: usize = undefined;
                i += try readNumber(usize, line[i..], &x);
                i += skipWhitespace(line[i..]);
                const color = readAlphabetic(line[i..]);
                i += color.len;

                if (color.len == 0) break;

                switch (color[0]) {
                    'r' => red = x,
                    'g' => green = x,
                    'b' => blue = x,
                    else => unreachable,
                }

                if (i >= line.len) break;

                switch (line[i]) {
                    ',' => i += 1,
                    ';' => {
                        i += 1;
                        break;
                    },
                    else => unreachable,
                }
            }

            if (red > 12 or green > 13 or blue > 14) {
                valid = false;
            }

            if (red > maxRed) maxRed = red;
            if (green > maxGreen) maxGreen = green;
            if (blue > maxBlue) maxBlue = blue;
        }

        if (valid) {
            total += id;
        }

        totalPower += maxRed * maxGreen * maxBlue;
    }

    std.debug.print("Sum: {any}\n", .{total});
    std.debug.print("Power: {any}\n", .{totalPower});
}
