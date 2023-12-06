const std = @import("std");

pub fn main() !void {
    var args = std.process.args();
    _ = args.next() orelse unreachable;

    const file = if (args.next()) |file_name| try std.fs.cwd().openFile(file_name, .{}) else std.io.getStdIn();
    defer file.close();
    var buff: [1024]u8 = undefined;
    const n = try file.readAll(&buff);
    const file_contents = buff[0..n];

    var lines = std.mem.splitScalar(u8, file_contents, '\n');
    var times = std.mem.tokenizeScalar(u8, lines.next().?["Time:".len..], ' ');
    var distances = std.mem.tokenizeScalar(u8, lines.next().?["Distance:".len..], ' ');

    var result: f64 = 1;

    while (times.next()) |time_str| {
        const time = try std.fmt.parseFloat(f64, time_str);
        const distance = try std.fmt.parseFloat(f64, distances.next().?);
        const sqrt_discriminant = std.math.sqrt(time * time + 4.0 * -distance);
        var x1 = -0.5 * (time + sqrt_discriminant);
        var x2 = -0.5 * (time - sqrt_discriminant);
        if (@mod(x1, 1.0) == 0) x1 += 1.0;
        if (@mod(x2, 1.0) == 0) x2 -= 1.0;
        result *= std.math.floor(x2) - std.math.ceil(x1) + 1;
    }

    std.debug.print("Result: {d}\n", .{result});
}
