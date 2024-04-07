#!/bin/sh
# 更新软件源
apk update
# 安装依赖项
apk add curl jq unzip openrc ca-certificates

# 获取最新版本号
LATEST_VERSION=$(curl -s https://api.github.com/repos/wyx2685/XrayR/releases/latest | jq -r '.tag_name')

# 提示用户输入版本号
echo "请输入 XrayR 的版本号 (直接回车将使用最新版本 $LATEST_VERSION):"
read -r USER_INPUT_VERSION

# 使用用户输入的版本号或默认到最新版本
VERSION=${USER_INPUT_VERSION:-$LATEST_VERSION}

# 检测系统架构并构建下载链接
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

# 下载 XrayR
curl -L -o XrayR.zip "$URL" || { echo "下载 XrayR 失败"; exit 1; }
# 解压缩
unzip XrayR.zip -d /etc/XrayR || { echo "解压 XrayR 失败"; exit 1; }
# 删除压缩包
rm XrayR.zip
# 添加执行权限
chmod +x /etc/XrayR/XrayR
# 创建软链接
ln -sf /etc/XrayR/XrayR /usr/bin/XrayR
# 创建 XrayR 服务文件
cat << "EOF" > /etc/init.d/XrayR
#!/sbin/openrc-run

depend() {
    need net
}

start() {
    ebegin "Starting XrayR"
    start-stop-daemon --start --exec /usr/bin/XrayR -- -config /etc/XrayR/config.yml
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
    start-stop-daemon --start --exec /usr/bin/XrayR -- -config /etc/XrayR/config.yml
    eend $?
}
EOF

# 添加执行权限
chmod +x /etc/init.d/XrayR

# 添加到开机启动项中
if rc-update add XrayR default; then
  echo "XrayR 已添加到启动项。"
else
  echo "添加 XrayR 到启动项失败。"
  exit 1
fi

echo "安装完成！"
