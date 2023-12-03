const std = @import("std");

pub fn main() !void {
    var reader = std.io.getStdIn().reader();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    var allocator = gpa.allocator();
    const input = try reader.readAllAlloc(allocator, 1024 * 100);
    var rowIterator = std.mem.splitScalar(u8, input, '\n');
    defer allocator.free(input);

    const n: usize = @intCast(std.math.sqrt(input.len));

    var sum: u32 = 0;
    var y: usize = 0;
    var nextRow = rowIterator.next();
    var prevRow: ?[]const u8 = null;

    while (y < n) : (y += 1) {
        const row = nextRow.?;
        nextRow = rowIterator.next();

        var x: usize = 0;
        while (x < n) : (x += 1) {
            var c = row[x];
            if (!std.ascii.isDigit(c)) continue;
            const lowerX = x;
            while (x < n and std.ascii.isDigit(row[x])) {
                c = row[x];
                x += 1;
            }
            const upperX = x;
            const numberLiteral = row[lowerX..upperX];
            const number = try std.fmt.parseUnsigned(u32, numberLiteral, 10);

            if (x < row.len and row[x] != '.') {
                sum += number;
            } else if ((lowerX != 0) and row[lowerX - 1] != '.') {
                sum += number;
            } else {
                const safeUpperX = @min(x + 1, row.len);
                const safeLowerX = if (lowerX == 0) 0 else (lowerX - 1);
                const adjacent: bool = blk: {
                    if (prevRow) |r| {
                        for (r[safeLowerX..safeUpperX]) |ca| {
                            if (ca != '.') {
                                break :blk true;
                            }
                        }
                    }

                    if (nextRow) |r| {
                        for (r[safeLowerX..safeUpperX]) |ca| {
                            if (ca != '.') {
                                break :blk true;
                            }
                        }
                    }

                    break :blk false;
                };

                if (adjacent) sum += number;
            }
        }

        prevRow = row;
    }

    std.debug.print("{any}\n", .{sum});
}
