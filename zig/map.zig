extern fn print(f32) void;
const std = @import("std");

pub const Map = struct {
    width: f32,
    height: f32,
    color_map_ptr: [*]const u8,
    height_map_ptr: [*]const u8,

    pub fn init(
        allocator: std.mem.Allocator,
        width: f32,
        height: f32,
        color_map_ptr: [*]const u8,
        height_map_ptr: [*]const u8
    ) *Map {
        const map_ptr = allocator.create(Map) catch unreachable;

        map_ptr.* = Map {
            .width = width,
            .height = height,
            .color_map_ptr = color_map_ptr,
            .height_map_ptr = height_map_ptr
        };

        return map_ptr;
    }
};
