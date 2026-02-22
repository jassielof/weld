const std = @import("std");

pub fn build(b: *std.Build) void {
    const mod_name = "weld";

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dotenv_dep = b.dependency(
        "dotenv",
        .{
            .target = target,
            .optimize = optimize,
        },
    );

    const yaml_dep = b.dependency(
        "yaml",
        .{
            .target = target,
            .optimize = optimize,
        },
    );

    const lib_mod = b.addModule(mod_name, .{
        .root_source_file = b.path("src/lib/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = mod_name,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/cli/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = mod_name,
                    .module = lib_mod,
                },
                .{
                    .name = "dotenv",
                    .module = dotenv_dep.module("dotenv"),
                },
                .{
                    .name = "yaml",
                    .module = yaml_dep.module("yaml"),
                },
            },
        }),
    });

    b.installArtifact(exe);

    const cli_step = b.step("cli", "Test the CLI");

    const run_cli = b.addRunArtifact(exe);
    cli_step.dependOn(&run_cli.step);

    run_cli.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cli.addArgs(args);
    }

    const lib = b.addLibrary(.{
        .name = mod_name,
        .root_module = lib_mod,
    });

    const docs = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    const docs_step = b.step("docs", "Generate the documentation");
    docs_step.dependOn(&docs.step);

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/suite.zig"),
            .optimize = optimize,
            .target = target,
            .imports = &.{.{
                .name = mod_name,
                .module = lib_mod,
            }},
        }),
    });

    const run_tests = b.addRunArtifact(tests);
    const tests_step = b.step("tests", "Run the test suite");
    tests_step.dependOn(&run_tests.step);
}
