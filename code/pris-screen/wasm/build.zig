const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const optimize = b.standardOptimizeOption(.{});

    const cols      = b.option(u32, "cols",      "Number of columns")           orelse 120;
    const rows      = b.option(u32, "rows",      "Number of rows")              orelse 40;
    const font_size = b.option(u32, "font-size", "Font size (selects font-N.zig)") orelse 16;

    const options = b.addOptions();
    options.addOption(u32, "n_cols", cols);
    options.addOption(u32, "n_rows", rows);

    const name = std.fmt.allocPrint(
        b.allocator, "pris-screen-{d}x{d}", .{ cols, rows },
    ) catch @panic("OOM");

    const font_file = std.fmt.allocPrint(
        b.allocator, "src/font-{d}.zig", .{font_size},
    ) catch @panic("OOM");

    const font_mod = b.createModule(.{ .root_source_file = b.path(font_file) });

    const lib = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "font",          .module = font_mod               },
                .{ .name = "build_options", .module = options.createModule() },
            },
        }),
    });

    lib.entry = .disabled;
    lib.rdynamic = true;
    b.installArtifact(lib);
}
