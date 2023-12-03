const std = @import("std");

const ProductList = struct {
    x: usize,
    y: usize,
    value: u32,
    n: usize,

    fn multiply(self: *const ProductList, num: u32) ProductList {
        return .{ .x = self.x, .y = self.y, .value = self.value * num, .n = self.n + 1 };
    }
};

fn multiplyByCoord(list: *std.ArrayList(ProductList), p: ProductList) std.mem.Allocator.Error!void {
    std.debug.print("multiplyByCoord({d}, {d}, {d})\n", .{ p.x, p.y, p.value });
    for (list.items, 0..) |item, i| {
        std.debug.print("\tProductList{{ .x = {d}, .y = {d}, .value = {d} }}\n", .{ item.x, item.y, item.value });
        if (item.x == p.x and item.y == p.y) {
            list.items[i] = item.multiply(p.value);
            std.debug.print(" => {d}\n", .{item.value});
            return;
        }
    }
    return list.append(p);
}

fn sumList(list: std.ArrayList(ProductList)) u32 {
    var sum: u32 = 0;
    for (list.items) |item| {
        if (item.n == 0) continue;
        sum += item.value;
    }
    return sum;
}

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

    var productList = std.ArrayList(ProductList).init(allocator);
    defer productList.deinit();

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

            if (x < row.len and row[x] == '*') {
                try multiplyByCoord(&productList, .{ x, y, number, 0 });
            }
            if ((lowerX != 0) and row[lowerX - 1] == '*') {
                try multiplyByCoord(&productList, .{ lowerX - 1, y, number, 0 });
            }

            const safeUpperX = @min(x + 1, row.len);
            const safeLowerX = if (lowerX == 0) 0 else (lowerX - 1);

            if (prevRow) |r| {
                for (r[safeLowerX..safeUpperX], 0..) |ca, i| {
                    if (ca == '*') {
                        try multiplyByCoord(&productList, .{ safeLowerX + i, y - 1, number, 0 });
                    }
                }
            }

            if (nextRow) |r| {
                for (r[safeLowerX..safeUpperX], 0..) |ca, i| {
                    if (ca == '*') {
                        try multiplyByCoord(&productList, .{ safeLowerX + i, y + 1, number, 0 });
                    }
                }
            }
        }

        prevRow = row;
    }

    const productSum = sumList(productList);

    std.debug.print("{any}\n{any}\n", .{ sum, productSum });
}
