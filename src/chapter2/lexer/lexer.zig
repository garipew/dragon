// The module "lexer" implements an equivalent to the lexical analyzer
// presented on section 2.6 of the book.
//
// Written by: @garipew
const std = @import("std");
const token = @import("token.zig");

pub const Lexer = struct {
    peek: u8,

    pub fn init() Lexer {
        return Lexer{
            .peek = ' ',
        };
    }

    fn skipWhitespace(self: *Lexer, reader: *std.Io.Reader) !void {
        while(std.ascii.isWhitespace(self.peek)) {
            self.peek = try reader.takeByte();
        }
    }

    fn skipComment(self: *Lexer, reader: *std.Io.Reader) !bool {
        if(self.peek != '/') {
            return false;
        }
        while(self.peek != '\n') {
            self.peek = try reader.takeByte();
        }
        return true;
    }

    fn skipCommentBlock(self: *Lexer, reader: *std.Io.Reader) !bool {
        if(self.peek != '*') {
            return false;
        }
        var prev: u8 = self.peek;
        self.peek = try reader.takeByte();
        while(prev != '*' or self.peek != '/') {
            prev = self.peek;
            self.peek = try reader.takeByte();
        }
        self.peek = ' ';
        return true;
    }

    fn readNumber(self: *Lexer, reader: *std.Io.Reader) !u64 {
        var value: u64 = 0; 
        while(std.ascii.isDigit(self.peek)) : (self.peek = try reader.takeByte()) {
                value = value * 10 + (self.peek - '0');
        }
        return value;
    }

    fn readId(self: *Lexer, allocator: std.mem.Allocator, reader: *std.Io.Reader) ![]u8 {
        var builder = std.ArrayList(u8).empty;
        errdefer builder.deinit(allocator);
        while(std.ascii.isAlphanumeric(self.peek) or self.peek == '_') : (self.peek = try reader.takeByte()) {
                try builder.append(allocator, self.peek);
        }
        return builder.toOwnedSlice(allocator);
    }

    fn readOperator(self: *Lexer, reader: *std.Io.Reader) !token.Operator {
        const first = self.peek;
        self.peek = try reader.takeByte();
        const op = try switch(first) {
            '+' => token.Operator.plus        ,
            '-' => token.Operator.minus       ,
            '*' => token.Operator.mult        ,
            '/' => token.Operator.div         ,
            '=' => token.Operator.assign      ,
            '>' => token.Operator.greater_than,
            '<' => token.Operator.less_than   ,
            '!' => token.Operator.not         ,
            ';' => token.Operator.end_stmt    ,
            else => error.UnknownOperator     ,
        };
        if(self.peek == '=' and @intFromEnum(op) < @intFromEnum(token.Operator.plus_assign)) {
            self.peek = ' ';
            return @enumFromInt(@intFromEnum(op) + @intFromEnum(token.Operator.plus_assign));
        }
        return op;
    }

    pub fn scan(self: *Lexer, allocator: std.mem.Allocator, reader: *std.Io.Reader) !token.Token {
        var t: token.Token = undefined;
        while(true) {
            try self.skipWhitespace(reader);
            if(std.ascii.isDigit(self.peek)) {
                return token.Token{ .num = try self.readNumber(reader), };
            }
            if(std.ascii.isAlphabetic(self.peek)) {
                return token.Token{ .id = try self.readId(allocator, reader), };
            }
            t = token.Token{ .op = try self.readOperator(reader), };
            if(t.op != token.Operator.div) {
                break;
            }
            if(!try self.skipComment(reader) and !try self.skipCommentBlock(reader)) {
                break;
            }
        }
        return t;
    }
};
