// This file contains the implementation of a translator from infix expressions
// to postfix expressions.
//
// The translator was built with the techniques presented up to the section 2.4
// of the dragon book (Compilers: Principles, Techniques and Tools).
//
// The grammar utilized in this translator is the following: 
//
// expr   -> expr + term    {print('+')}
// expr   -> expr - term    {print('-')}
// expr   -> term
// term   -> term * factor  {print('*')}
// term   -> term / factor  {print('/')}
// term   -> factor
// factor -> (expr);
// factor -> 0              {print('0')}
// factor -> 1              {print('1')}
// factor -> 2              {print('2')}
// factor -> 3              {print('3')}
// factor -> 4              {print('4')}
// factor -> 5              {print('5')}
// factor -> 6              {print('6')}
// factor -> 7              {print('7')}
// factor -> 8              {print('8')}
// factor -> 9              {print('9')}
//
// The remaining of this block breaks down the rewriting of the above in a
// right-recursive grammar.
//
// The left-recursive grammar of the form:
// 
// A -> A alfa | beta
//
// Where alfa and beta are sequences of terminals and nonterminals that do not
// start with A, can be rewritten as a right-recursive grammar on the form:
//
// A -> beta R
// R -> alfa R | empty
//
// Where R is nonterminal added to the grammar.
//
// ================= Right-recursive form =================
//
// expr   ->   term                      R
// R      -> - term         {print('-')} R
// R      -> + term         {print('+')} R 
// R      ->   empty
// term   ->   factor                    S
// S      -> * factor       {print('*')} S 
// S      -> / factor       {print('/')} S
// S      ->   empty
// factor -> ( expr )
// factor -> 0              {print('0')}
// factor -> 1              {print('1')}
// factor -> 2              {print('2')}
// factor -> 3              {print('3')}
// factor -> 4              {print('4')}
// factor -> 5              {print('5')}
// factor -> 6              {print('6')}
// factor -> 7              {print('7')}
// factor -> 8              {print('8')}
// factor -> 9              {print('9')}
//
// ========================================================
//
// Written by: @garipew

const std = @import("std");
const Io = std.Io;

const terminal = enum {
	ZERO,
	ONE,
	TWO,
	THREE,
	FOUR,
	FIVE,
	SIX,
	SEVEN,
	EIGHT,
	NINE,
	PLUS,
	MINUS,
	MUL,
	DIV,
	OPEN_PARENTHESIS,
	CLOSE_PARENTHESIS,
	UNKNOWN
};

const compilerError = error { SYNTAX_ERROR } || Io.Reader.Error || Io.Writer.Error;

var lookahead : terminal = .UNKNOWN;

fn get_next(reader: *Io.Reader) compilerError!terminal {
	const c = try reader.takeByte();

	const next: terminal = switch(c) {
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' =>
            @as(terminal, @enumFromInt(c - '0')),
        '+' =>
            .PLUS,
        '-' => .MINUS,
        '*' => .MUL,
        '/' => .DIV,
        '(' => .OPEN_PARENTHESIS,
        ')' => .CLOSE_PARENTHESIS,
        else => .UNKNOWN,
    };
	return next;
}

pub fn match(reader: *Io.Reader, t: terminal) compilerError!void {
	if(t == lookahead) {
		lookahead = try get_next(reader);
		return;
	}
    return compilerError.SYNTAX_ERROR;
}

pub fn factor(reader: *Io.Reader, writer: *Io.Writer) compilerError!void {
	switch(lookahead) {
        .ZERO => {
            try match(reader, .ZERO);
            try writer.print("0", .{});
        },
        .ONE => {
            try match(reader, .ONE);
            try writer.print("1", .{});
        },
        .TWO => {
            try match(reader, .TWO);
            try writer.print("2", .{});
        },
        .THREE => {
            try match(reader, .THREE);
            try writer.print("3", .{});
        },
        .FOUR => {
            try match(reader, .FOUR);
            try writer.print("4", .{});
        },
        .FIVE => {
            try match(reader, .FIVE);
            try writer.print("5", .{});
        },
        .SIX => {
            try match(reader, .SIX);
            try writer.print("6", .{});
        },
        .SEVEN => {
            try match(reader, .SEVEN);
            try writer.print("7", .{});
        },
        .EIGHT => {
            try match(reader, .EIGHT);
            try writer.print("8", .{});
        },
        .NINE => {
            try match(reader, .NINE);
            try writer.print("9", .{});
        },
        .OPEN_PARENTHESIS => {
            try match(reader, .OPEN_PARENTHESIS);
            try expr(reader, writer);
            try match(reader, .CLOSE_PARENTHESIS);
        },
        else =>
            return compilerError.SYNTAX_ERROR,
	}
}

pub fn S(reader: *Io.Reader, writer: *Io.Writer) !void {
    while(true) {
        switch(lookahead) {
            .MUL => {
                try match(reader, .MUL);
                try factor(reader, writer);
                try writer.print("*", .{});
            },
            .DIV => {
                try match(reader, .DIV);
                try factor(reader, writer);
                try writer.print("/", .{});
            },
            else => {
                // Empty production is valid
                return;
            },
        }
    }
}

pub fn term(reader: *Io.Reader, writer: *Io.Writer) !void {
	try factor(reader, writer);
	try S(reader, writer);
}

pub fn R(reader: *Io.Reader, writer: *Io.Writer) !void {
    while(true) {
        switch(lookahead) {
            .PLUS => {
                try match(reader, .PLUS);
                try term(reader, writer);
                try writer.print("+", .{});
            },
            .MINUS => {
                try match(reader, .MINUS);
                try term(reader, writer);
                try writer.print("-", .{});
            },
            else => {
                // Empty production is valid
                return;
            },
        }
    }
}

pub fn expr(reader: *Io.Reader, writer: *Io.Writer) !void {
    try term(reader, writer);
    try R(reader, writer);
}

pub fn main(init: std.process.Init) !void {
    // In order to do I/O operations need an `Io` instance.
    const io = init.io;

    // Stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_file_reader: Io.File.Reader = .init(.stdin(), io, &stdin_buffer);
    const stdin_reader = &stdin_file_reader.interface;

    while(true) {
        try stdout_writer.print("< ", .{});
        try stdout_writer.flush(); // Don't forget to flush!
        lookahead = get_next(stdin_reader) catch | err | {
            if(err == error.EndOfStream) {
                return;
            }
            return err;
        };
        try stdout_writer.print("> ", .{});
		try expr(stdin_reader, stdout_writer);
        try stdout_writer.print("\n", .{});
        try stdout_writer.flush(); // Don't forget to flush!
    }
}
