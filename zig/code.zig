extern fn writeToCanvas([*]const u8) void;
extern fn print(f32) void;
extern fn printColor(u8, u8, u8) void;

var allocator = @import("std").heap.wasm_allocator;

var buffer_op: ?[]u8 = null;

export fn computeCanvas(
    buffer_width: f32, buffer_height: f32,
    color_map_ptr: [*]u8, color_map_width: f32, color_map_height: f32,
    height_map_ptr: [*]u8, height_map_width: f32, height_map_height: f32
) void {
    const buffer_len: u32 = @intFromFloat(buffer_width * buffer_height * 4.0);

    _ = height_map_width;
    _ = height_map_height;

    if (buffer_op) |buffer| {
        _ = allocator.resize(buffer, buffer_len);
    } else {
        buffer_op = allocator.alloc(u8, buffer_len) catch return;
    }

    if (buffer_op) |buffer| {
        const px: f32 = color_map_width / 2.0;
        //const px = 250.0;
        const py: f32 = color_map_height / 2.0;
        //const py = 80.0;
        const d_max: f32 = 300.0;
        const fov: f32 = 2.0;

        const focal_length = 120.0;

        for (1..@intFromFloat(d_max)) |i_d| {
            const f_i_d: f32 = @floatFromInt(i_d);

            const d: f32 = d_max - f_i_d;
            const map_y = @floor(py - d);
            const map_y_mod = @mod(map_y, color_map_height);

            const dx = d * fov;

            for (0..@intFromFloat(buffer_width)) |x| {
                const f_x: f32 = @floatFromInt(x);

                const map_x = @floor(px - (dx / 2.0) + f_x / buffer_width * dx);
                const map_x_mod = @mod(map_x, color_map_width);

                const index = idx(map_x_mod, map_y_mod, color_map_width);
                const color_ptr = color_map_ptr + index;

                //printColor(color_ptr[0], color_ptr[1], color_ptr[2]);
                const height_map_value: f32 = @floatFromInt(height_map_ptr[index]);

                //const percentage = height_map_value / 155.0;
                //const height: u32 = @intFromFloat(buffer_height - buffer_height * percentage);
                //_ = height;

                var height_on_screen: f32 = (height_map_value + 100) / (focal_length * d);
                height_on_screen = @min(height_on_screen, buffer_height - 1.0);
                height_on_screen = @max(height_on_screen, 1);

                for (@intFromFloat(height_on_screen)..@intFromFloat(buffer_height)) |y| {
                    const f_y: f32 = @floatFromInt(y);
                    buffer[idx(f_x, f_y, buffer_width)] = color_ptr[0];
                    buffer[idx(f_x, f_y, buffer_width) + 1] = color_ptr[1];
                    buffer[idx(f_x, f_y, buffer_width) + 2] = color_ptr[2];
                    buffer[idx(f_x, f_y, buffer_width) + 3] = 255;
                }
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
