extern fn writeToCanvas([*]const u8) void;
extern fn print(f32) void;
extern fn printColor(u8, u8, u8) void;

const std = @import("std");
var allocator = std.heap.wasm_allocator;

var buffer_op: ?[]u8 = null;
var max_y_buffer: []u32 = undefined;

export fn computeCanvas(
    px: f32, py: f32,
    buffer_width: f32, buffer_height: f32,
    color_map_ptr: [*]u8, color_map_width: f32, color_map_height: f32,
    height_map_ptr: [*]u8, height_map_width: f32, height_map_height: f32
) void {
    const buffer_len: u32 = @intFromFloat(buffer_width * buffer_height * 4.0);

    const px_mod = @mod(px, color_map_width);
    const py_mod = @mod(py, color_map_height);

    _ = height_map_width;
    _ = height_map_height;

    if (buffer_op) |buffer| {
        buffer_op = allocator.realloc(buffer, buffer_len) catch return;
        max_y_buffer = allocator.realloc(max_y_buffer, u(buffer_width)) catch return;
    } else {
        buffer_op = allocator.alloc(u8, buffer_len) catch return;
        max_y_buffer = allocator.alloc(u32, u(buffer_width)) catch return;
    }

    if (buffer_op) |buffer| {
        for (0..max_y_buffer.len) |mxi| {
            max_y_buffer[mxi] = u(buffer_height);
        }

        const render_distance: f32 = 450.0;
        const camera_height: f32 = f(height_map_ptr[idx(px_mod, py_mod, color_map_width)]) + 50.0;

        const fov: f32 = 90.0;
        const fov_rad: f32 = std.math.degreesToRadians(fov);
        const focal_length = (buffer_height / 2.0) * (1 / std.math.tan(fov_rad / 2.0));

        for (1..@intFromFloat(render_distance)) |i_d| {
            const d: f32 = @floatFromInt(i_d);
            const map_y = @floor(py - d);
            const map_y_mod = @mod(map_y, color_map_height);

            const dx = d * (buffer_width / focal_length);

            for (0..@intFromFloat(buffer_width)) |x| {
                const f_x: f32 = @floatFromInt(x);

                const map_x = @floor(px - (dx / 2.0) + f_x / buffer_width * dx);
                const map_x_mod = @mod(map_x, color_map_width);

                const index = idx(map_x_mod, map_y_mod, color_map_width);
                const color_ptr = color_map_ptr + index;

                const height_map_value: f32 = @floatFromInt(height_map_ptr[index]);

                var height_on_screen: f32 = (camera_height - height_map_value) * (focal_length / d) + 300.0;
                height_on_screen = std.math.clamp(height_on_screen, 0.0, buffer_height - 1.0);

                if(max_y_buffer[x] > i(height_on_screen)){
                    for (u(height_on_screen)..max_y_buffer[x]) |y| {
                        const f_y: f32 = @floatFromInt(y);
                        buffer[idx(f_x, f_y, buffer_width)] = color_ptr[0];
                        buffer[idx(f_x, f_y, buffer_width) + 1] = color_ptr[1];
                        buffer[idx(f_x, f_y, buffer_width) + 2] = color_ptr[2];
                        buffer[idx(f_x, f_y, buffer_width) + 3] = 255;
                    }
                    max_y_buffer[x] = u(height_on_screen);
                }
            }
        }

        for(0..u(buffer_width)) |x| {
            for (0..max_y_buffer[x]) |y| {
                buffer[idx(f(x), f(y), buffer_width)] = 102;
                buffer[idx(f(x), f(y), buffer_width) + 1] = 163;
                buffer[idx(f(x), f(y), buffer_width) + 2] = 255;
                buffer[idx(f(x), f(y), buffer_width) + 3] = 255;
            }
        }

        writeToCanvas(buffer.ptr);
    }
}

export fn allocImageBuffer(size: u32) *u8 {
    return @ptrCast(allocator.alloc(u8, size) catch unreachable);
}

fn idx(x: f32, y: f32, width: f32) u32 {
    return @intFromFloat((y * width + x) * 4.0);
}

fn f(x: anytype) f32 {
    return @as(f32, @floatFromInt(x));
}

fn i(x: anytype) i32 {
    return @as(i32, @intFromFloat(x));
}

fn u(x: anytype) u32 {
    return @as(u32, @intFromFloat(x));
}

pub fn rgbaToInt(r: u8, g: u8, b: u8, a: u8) u32 {
    return (@as(u32, a) << 24) |
           (@as(u32, r) << 16) |
           (@as(u32, g) << 8)  |
            @as(u32, b);
}
