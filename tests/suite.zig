const std = @import("std");
const testing = std.testing;

comptime {}

test {
    testing.refAllDecls(@This());
}
