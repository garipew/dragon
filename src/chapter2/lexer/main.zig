const std = @import("std");
const lexer = @import("lexer");

const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const arena = init.arena;
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_file_reader: Io.File.Reader = .init(.stdin(), io, &stdin_buffer);
    const stdin_reader = &stdin_file_reader.interface;

    var lex = lexer.Lexer.init();
    while(true) {
        const token = lex.scan(arena.allocator(), stdin_reader) catch | err | {
            if(err == error.EndOfStream) {
                return;
            }
            return err;
        };
        switch(token) {
            .num => | n | try stdout_writer.print("<num, {d}>", .{n}),
            .op  => | o | try stdout_writer.print("<op , {} >", .{o}),
            .id  => | i | try stdout_writer.print("<id , {s}>", .{i}),
        }
        try stdout_writer.print("\n", .{});
        try stdout_writer.flush(); // Don't forget to flush!
    }
}
