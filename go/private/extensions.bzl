load("//go/private:sdk.bzl", "go_download_sdk", "go_host_sdk")
load("//go/private:repositories.bzl", "go_rules_dependencies")

_download_tag = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "goos": attr.string(),
        "goarch": attr.string(),
        "sdks": attr.string_list_dict(),
        "urls": attr.string_list(default = ["https://dl.google.com/go/{}"]),
        "version": attr.string(),
        "strip_prefix": attr.string(default = "go"),
    },
)

_host_tag = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "version": attr.string(),
    },
)

def _go_sdk_impl(ctx):
    for module in ctx.modules:
        for download_tag in module.tags.download:
            # SDKs without an explicit version are fetched even when not selected by toolchain
            # resolution. This is acceptable if brought in by the root module, but transitive
            # dependencies should not slow down the build in this way.
            if not module.is_root and not download_tag.version:
                fail("go_sdk.download: version must be specified in non-root module " + module.name)
            go_download_sdk(
                name = download_tag.name,
                goos = download_tag.goos,
                goarch = download_tag.goarch,
                sdks = download_tag.sdks,
                urls = download_tag.urls,
                version = download_tag.version,
                register_toolchains = False,
            )
        for host_tag in module.tags.host:
            # Dependencies can rely on rules_go providing a default remote SDK. They can also
            # configure a specific version of the SDK to use. However, they should not add a
            # dependency on the host's Go SDK.
            if not module.is_root:
                fail("go_sdk.host: cannot be used in non-root module " + module.name)
            go_host_sdk(
                name = host_tag.name,
                version = host_tag.version,
                register_toolchains = False,
            )

go_sdk = module_extension(
    implementation = _go_sdk_impl,
    tag_classes = {
        "download": _download_tag,
        "host": _host_tag,
    },
)

def _non_module_dependencies_impl(_ctx):
    go_rules_dependencies(force = True)

non_module_dependencies = module_extension(
    implementation = _non_module_dependencies_impl,
)
