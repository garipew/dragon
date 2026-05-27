const std = @import("std");

pub const Operator = enum {
    plus,
    minus,
    mult,
    div,
    assign,
    greater_than,
    less_than,
    not,
    plus_assign,
    minus_assign,
    mult_assign,
    div_assign,
    equals,
    greater_equal_than,
    less_equal_than,
    not_equal,
    end_stmt,
};

pub const Token = union(enum) {
    num : u64,
    id: []const u8,
    op: Operator,
};
