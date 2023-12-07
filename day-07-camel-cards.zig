const std = @import("std");

const MAX_FILE_SIZE = 100 * 1024;
const MAX_CARDS = 1000;

inline fn cardToValue(card: u8) u8 {
    return switch (card) {
        '2' => 0,
        '3' => 1,
        '4' => 2,
        '5' => 3,
        '6' => 4,
        '7' => 5,
        '8' => 6,
        '9' => 7,
        'T' => 8,
        'J' => 9,
        'Q' => 10,
        'K' => 11,
        'A' => 12,
        else => unreachable,
    };
}

const hand_type = enum(u8) {
    high_card = 0,
    pair = 1,
    two_pair = 2,
    three_of_a_kind = 3,
    full_house = 4,
    four_of_a_kind = 5,
    five_of_a_kind = 6,

    fn fromCards(cards: *const [5]u8) hand_type {
        var card_counts: [13]u8 = undefined;

        inline for (0..card_counts.len) |i|
            card_counts[i] = 0;

        for (cards) |c|
            card_counts[cardToValue(c)] += 1;

        var pair_count: usize = 0;
        var three_of_a_kind = false;

        for (card_counts) |count| {
            if (count == 2) {
                pair_count += 1;
            } else if (count == 3) {
                three_of_a_kind = true;
            } else if (count == 4) {
                return .four_of_a_kind;
            } else if (count == 5) {
                return .five_of_a_kind;
            }
        }

        return if (three_of_a_kind and pair_count == 1)
            .full_house
        else if (three_of_a_kind)
            .three_of_a_kind
        else if (pair_count == 2)
            .two_pair
        else if (pair_count == 1)
            .pair
        else
            .high_card;
    }
};

const hand = struct {
    type: hand_type,
    cards: *const [5]u8,
    bid: u32,

    fn new(cards: *const [5]u8, bid: u32) hand {
        return hand{
            .type = hand_type.fromCards(cards),
            .cards = cards,
            .bid = bid,
        };
    }

    fn lessThan(_: @TypeOf(.{}), self: hand, other: hand) bool {
        if (self.type != other.type) {
            return @intFromEnum(self.type) < @intFromEnum(other.type);
        }

        for (0..self.cards.len) |i| {
            if (self.cards[i] != other.cards[i]) {
                return cardToValue(self.cards[i]) < cardToValue(other.cards[i]);
            }
        }

        return false;
    }
};

pub fn main() !void {
    var args = std.process.args();
    _ = args.next() orelse unreachable;

    const file = if (args.next()) |file_name|
        try std.fs.cwd().openFile(file_name, .{})
    else
        std.io.getStdIn();

    defer file.close();

    var buff: [MAX_FILE_SIZE]u8 = undefined;
    const n = try file.readAll(&buff);
    const file_contents = buff[0..n];

    var lines = std.mem.splitScalar(u8, file_contents, '\n');

    var hands_buff: [MAX_CARDS]hand = undefined;
    var n_hands: usize = 0;

    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var parts = std.mem.splitScalar(u8, line, ' ');
        const cards = parts.next() orelse unreachable;
        const bid = try std.fmt.parseInt(u32, parts.next() orelse unreachable, 10);
        const h = hand.new(cards[0..5], bid);
        hands_buff[n_hands] = h;
        n_hands += 1;
    }

    var hands = hands_buff[0..n_hands];
    std.sort.heap(hand, hands, .{}, hand.lessThan);

    var result: usize = 0;
    for (hands, 0..) |h, i| {
        result += (i + 1) * h.bid;
    }

    std.debug.print("Result: {d}\n", .{result});
}
