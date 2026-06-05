const std = @import("std");

pub fn build(b: *std.Build) void {
    const target   = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Grid size for keyframes — must match the pris-screen build.
    const cols = b.option(u32, "cols", "Number of columns") orelse 92;
    const rows = b.option(u32, "rows", "Number of rows")    orelse 36;

    const options = b.addOptions();
    options.addOption(u32, "n_cols", cols);
    options.addOption(u32, "n_rows", rows);
    const opts_mod = options.createModule();

    // Shared terminal core (also used by the pris-screen WASM renderer).
    const terminal_mod = b.createModule(.{
        .root_source_file = b.path("../pris-screen/wasm/src/terminal.zig"),
        .imports = &.{
            .{ .name = "build_options", .module = opts_mod },
        },
    });

    const exe = b.addExecutable(.{
        .name    = "pris-chunk-writer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target   = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "terminal", .module = terminal_mod },
            },
        }),
    });

    b.installArtifact(exe);
}
