#!/bin/sh

install_xrayr() {
    apk update
    apk add ca-certificates curl jq openrc unzip vim

    LATEST_VERSION=$(curl -s https://api.github.com/repos/wyx2685/XrayR/releases/latest | jq -r '.tag_name')

    echo "请输入 XrayR 的版本号 (直接回车将使用最新版本 $LATEST_VERSION):"
    read -r USER_INPUT_VERSION

    VERSION=${USER_INPUT_VERSION:-$LATEST_VERSION}

    ARCH=$(uname -m)
    BASE_URL="https://github.com/wyx2685/XrayR/releases/download"
    FILE=""

    case "$ARCH" in
        "x86_64")
            FILE="XrayR-linux-64.zip"
            ;;
        "i386" | "i686")
            FILE="XrayR-linux-32.zip"
            ;;
        "aarch64")
            FILE="XrayR-linux-arm64-v8a.zip"
            ;;
        *)
            echo "不支持的架构: $ARCH"
            exit 1
            ;;
    esac

    URL="$BASE_URL/$VERSION/$FILE"

    curl -L -o XrayR.zip "$URL" || { echo "下载 XrayR 失败"; exit 1; }
    unzip XrayR.zip -d /etc/XrayR || { echo "解压 XrayR 失败"; exit 1; }
    rm XrayR.zip
    chmod +x /etc/XrayR/XrayR
    ln -sf /etc/XrayR/XrayR /usr/bin/XrayR

    cat << "EOF" > /etc/init.d/XrayR
#!/sbin/openrc-run

depend() {
    need net
}

start() {
    ebegin "Starting XrayR"
    start-stop-daemon --start --exec /usr/bin/XrayR -- --config /etc/XrayR/config.yml >> /var/log/XrayR.log 2>&1
    eend $?
}

stop() {
    ebegin "Stopping XrayR"
    start-stop-daemon --stop --exec /usr/bin/XrayR
    eend $?
}

restart() {
    ebegin "Restarting XrayR"
    start-stop-daemon --stop --exec /usr/bin/XrayR
    sleep 1
    start-stop-daemon --start --exec /usr/bin/XrayR -- --config /etc/XrayR/config.yml >> /var/log/XrayR.log 2>&1
    eend $?
}
EOF

    chmod +x /etc/init.d/XrayR

    if rc-update add XrayR default; then
        echo "XrayR 已添加到启动项。"
    else
        echo "添加 XrayR 到启动项失败。"
        exit 1
    fi

    echo "安装完成！"
}

update_xrayr() {
    echo "更新 XrayR..."
    # 先停止服务
    rc-service XrayR stop

    apk update
    apk add ca-certificates curl jq openrc unzip vim

    LATEST_VERSION=$(curl -s https://api.github.com/repos/wyx2685/XrayR/releases/latest | jq -r '.tag_name')

    echo "请输入 XrayR 的版本号 (直接回车将使用最新版本 $LATEST_VERSION):"
    read -r USER_INPUT_VERSION

    VERSION=${USER_INPUT_VERSION:-$LATEST_VERSION}

    ARCH=$(uname -m)
    BASE_URL="https://github.com/wyx2685/XrayR/releases/download"
    FILE=""

    case "$ARCH" in
        "x86_64")
            FILE="XrayR-linux-64.zip"
            ;;
        "i386" | "i686")
            FILE="XrayR-linux-32.zip"
            ;;
        "aarch64")
            FILE="XrayR-linux-arm64-v8a.zip"
            ;;
        *)
            echo "不支持的架构: $ARCH"
            exit 1
            ;;
    esac

    URL="$BASE_URL/$VERSION/$FILE"

    curl -L -o XrayR.zip "$URL" || { echo "下载 XrayR 失败"; exit 1; }
    
    # 解压文件，排除config.yml以避免覆盖
    unzip -o XrayR.zip -d /etc/XrayR -x *config.yml || { echo "解压 XrayR 失败"; exit 1; }
    
    rm XrayR.zip
    chmod +x /etc/XrayR/XrayR
    ln -sf /etc/XrayR/XrayR /usr/bin/XrayR
    
    # 再启动服务
    rc-service XrayR start

    echo "XrayR 更新完成！"
}

menu() {
  while true; do
    echo "选择一个操作:"
    echo "1) 安装 XrayR"
    echo "2) 启动 XrayR"
    echo "3) 停止 XrayR"
    echo "4) 查看 XrayR 日志"
    echo "5) 更新 XrayR"
    echo "6) 修改 XrayR 配置"
    echo "7) 重启 XrayR"
    echo "8) 卸载 XrayR"
    echo "9) 退出"
    read -p "请输入选项 [1-9]: " option

    case $option in
        1)
            install_xrayr
            ;;
        2)
            echo "启动 XrayR 服务..."
            rc-service XrayR start
            ;;
        3)
            echo "停止 XrayR 服务..."
            rc-service XrayR stop
            ;;
        4)
            echo "显示 XrayR 日志... (按 q 退出日志查看)"
            tail -f /var/log/XrayR.log
            ;;
        5)
            update_xrayr
            ;;
        6)
            echo "修改 XrayR 配置..."
            vim /etc/XrayR/config.yml
            rc-service XrayR restart
            ;;
        7)
            echo "重启 XrayR 服务..."
            restart
            ;;
        8)
            echo "卸载 XrayR..."
            rc-service XrayR stop
            rc-update del XrayR default
            rm -rf /etc/XrayR
            rm /usr/bin/XrayR
            echo "XrayR 已卸载！"
            ;;
        9)
            echo "退出菜单..."
            exit 0
            ;;
        *)
            echo "无效选项，请重新输入..."
            ;;
    esac
  done
}

menu
