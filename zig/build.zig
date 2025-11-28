const std = @import("std");

pub fn build(b: *std.Build) void {
    // 0.15.0-dev
    const exe = b.addExecutable(.{
        .name = "code",
        .root_source_file = b.path("code.zig"),
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
        }),
        .optimize = b.standardOptimizeOption(.{}),
    });

    // 0.15.2
    // const exe = b.addExecutable(.{
    //     .name = "code",
    //     .root_module = b.createModule(.{
    //         .root_source_file = b.path("code.zig"),
    //         .target = b.resolveTargetQuery(.{
    //             .cpu_arch = .wasm32,
    //             .os_tag = .freestanding,
    //         }),
    //         .optimize = b.standardOptimizeOption(.{}),
    //     }),
    // });

    exe.entry = .disabled;

    exe.rdynamic = true;

    b.installArtifact(exe);
}
