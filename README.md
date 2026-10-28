# LightOS Remote Desktop Nix flake

本 flake 从上游固定版本 `v0.1.21` 构建 [LightOS Remote Desktop](https://github.com/ca-x/lightos-remote-desktop)。构建时会先生成并嵌入锁定版本的网页前端，再使用上游正式构建功能 `bundled-jpeg`、`rdp` 和 `portal` 编译 Rust 主程序。

上游采用 PolyForm Noncommercial 1.0.0 许可证。该软件可再分发，但属于非自由软件，因此构建时需要允许此包：

```sh
NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#lightos-remoted
NIXPKGS_ALLOW_UNFREE=1 nix run --impure . -- --version
NIXPKGS_ALLOW_UNFREE=1 nix run --impure . -- doctor
```

## 安装到 NixOS

在 NixOS 配置 flake 的 `inputs` 中添加：

```nix
lightos-remote-desktop.url = "github:zerokaze420/lightos-remote-desktop-flake";
lightos-remote-desktop.inputs.nixpkgs.follows = "nixpkgs";
```

然后在对应主机的 NixOS module 中允许此非自由软件，并加入系统软件包：

```nix
({ pkgs, lib, ... }: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "lightos-remoted" ];

  environment.systemPackages = [
    lightos-remote-desktop.packages.${pkgs.system}.default
  ];
})
```

应用配置后，可在主机上运行 `lightos-remoted --version` 或 `lightos-remoted doctor` 验证安装。将 `nixos-rebuild switch --flake .#主机名` 中的主机名替换为配置中的名称。

此包提供 `lightos-remoted` 服务程序，但目前没有打包 NixOS systemd unit，也不会自动配置桌面环境。可以先在终端手动启动：

```sh
lightos-remoted serve --listen 127.0.0.1 --port 8766 --password '替换为自己的密码'
```

然后访问 `http://127.0.0.1:8766`，使用默认用户名 `lightos` 和设置的密码登录。桌面采集、输入和音频还需要主机具备上游列出的桌面环境与运行依赖；详见[上游安装指南](https://github.com/ca-x/lightos-remote-desktop/blob/v0.1.21/docs/install.md)。

不要将密码直接写入 NixOS 配置，因为配置内容可能进入 Nix store。若要开机自动启动，请在 NixOS 中自行声明 systemd 服务，并使用专门的密钥管理方案提供密码。不要在 NixOS 上运行上游 `install-service`，它会写入常规 `/usr` 和 `/etc` 路径。
