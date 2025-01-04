#!/bin/bash

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local REPO_NAME=$(echo $PKG_REPO | cut -d '/' -f 2)

	rm -rf $(find ./ ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune)

	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

	if [[ $PKG_SPECIAL == "pkg" ]]; then
		cp -rf $(find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune) ./
		rm -rf ./$REPO_NAME/
	elif [[ $PKG_SPECIAL == "name" ]]; then
		mv -f $REPO_NAME $PKG_NAME
	fi
}

#UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
# UPDATE_PACKAGE "argon" "jerrykuku/luci-theme-argon" "master"
# UPDATE_PACKAGE "kucat" "sirpdboy/luci-theme-kucat" "js"

# UPDATE_PACKAGE "homeproxy" "VIKINGYFY/homeproxy" "main"
# UPDATE_PACKAGE "mihomo" "morytyann/OpenWrt-mihomo" "main"
# UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
# UPDATE_PACKAGE "passwall" "xiaorouji/openwrt-passwall" "main" "pkg"
# UPDATE_PACKAGE "ssr-plus" "fw876/helloworld" "master"

# UPDATE_PACKAGE "alist" "sbwml/luci-app-alist" "main"
# UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5"
# UPDATE_PACKAGE "vnt" "lazyoop/networking-artifact" "main" "pkg"
# UPDATE_PACKAGE "easytier" "lazyoop/networking-artifact" "main" "pkg"

# UPDATE_PACKAGE "istore" "linkease/istore" "main"


# UPDATE_PACKAGE "luci-app-advancedplus" "VIKINGYFY/packages" "main" "pkg"
# UPDATE_PACKAGE "luci-app-gecoosac" "lwb1978/openwrt-gecoosac" "main"
# UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"
# UPDATE_PACKAGE "luci-app-wolplus" "VIKINGYFY/packages" "main" "pkg"

if [[ $WRT_REPO != *"immortalwrt"* ]]; then
	UPDATE_PACKAGE "qmi-wwan" "immortalwrt/wwan-packages" "master" "pkg"
fi

#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-not}
	local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	echo " "

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo "$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Pho 'PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)' $PKG_FILE | head -n 1)
		local PKG_VER=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease|$PKG_MARK)) | first | .tag_name")
		local NEW_VER=$(echo $PKG_VER | sed "s/.*v//g; s/_/./g")
		local NEW_HASH=$(curl -sL "https://codeload.github.com/$PKG_REPO/tar.gz/$PKG_VER" | sha256sum | cut -b -64)
		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")

		echo "$OLD_VER $PKG_VER $NEW_VER $NEW_HASH"

		if [[ $NEW_VER =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

#UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
# UPDATE_VERSION "sing-box"
# UPDATE_VERSION "tailscale"






# # 显示当前工作目录
# echo "Current working directory: $(pwd)"

# # 硬编码 OpenWRT 根目录路径
# OPENWRT_ROOT="/home/runner/work/openwrt-ci/openwrt-ci/openwrt"

# # 确认 OpenWRT 根目录路径是否存在
# if [ ! -d "$OPENWRT_ROOT" ]; then
#     echo "Error: Unable to locate OpenWRT root directory at $OPENWRT_ROOT!"
#     exit 1
# fi

# echo "Detected OpenWRT root directory: $OPENWRT_ROOT"

# # 确认 feeds.conf.default 是否存在
# if [ ! -f "$OPENWRT_ROOT/feeds.conf.default" ]; then
#     echo "Error: Unable to locate feeds.conf.default at $OPENWRT_ROOT/feeds.conf.default!"
#     exit 1
# fi

# # 定义下载文件的 URL 和目标路径
# FILE_URL="https://github.com/linkease/istore-ui/archive/refs/tags/v0.1.27-2.tar.gz"
# TARGET_DIR="$OPENWRT_ROOT/dl"
# TARGET_FILE="$TARGET_DIR/istore-ui-v0.1.27-2.tar.gz"

# # 确保下载目录存在
# if [ ! -d "$TARGET_DIR" ]; then
#     echo "Directory $TARGET_DIR does not exist. Creating..."
#     mkdir -p "$TARGET_DIR"
# fi

# # 添加新的 feeds 并更新安装 istore 相关软件包
# echo "Adding istore feed to feeds.conf.default..."
# echo >> "$OPENWRT_ROOT/feeds.conf.default"
# echo 'src-git istore https://github.com/washsky/istore;washsky-patch-1' >> "$OPENWRT_ROOT/feeds.conf.default"

# # 更新 istore feed
# echo "Updating istore feed..."
# "$OPENWRT_ROOT/scripts/feeds" update istore || { echo "Failed to update istore feed."; exit 1; }

# # 手动下载文件控制
# if [ ! -f "$TARGET_FILE" ]; then
#     echo "File $TARGET_FILE not found. Attempting to download manually..."

#     # 尝试通过 wget 下载文件，并增加 -v 选项显示调试信息
#     wget -v --connect-timeout=20 --tries=5 --timeout=20 --retry-connrefused --no-check-certificate "$FILE_URL" -O "$TARGET_FILE"

#     if [ $? -ne 0 ]; then
#         echo "Download failed from primary URL: $FILE_URL. Attempting to use a fallback URL..."

#         # 尝试使用备用 URL 下载
#         FALLBACK_URL="https://mirror2.immortalwrt.org/sources/istore-ui-v0.1.27-2.tar.gz"
#         wget -v --connect-timeout=20 --tries=5 --timeout=20 --retry-connrefused --no-check-certificate "$FALLBACK_URL" -O "$TARGET_FILE"

#         if [ $? -ne 0 ]; then
#             echo "Download from fallback URL also failed. Exiting."
#             exit 1
#         else
#             echo "File downloaded successfully from fallback URL."
#         fi
#     else
#         echo "File downloaded successfully from primary URL."
#     fi
# else
#     echo "File already exists at $TARGET_FILE."
# fi

# # 安装 luci-app-store 包
# echo "Installing luci-app-store package from istore feed..."
# "$OPENWRT_ROOT/scripts/feeds" install -d y -p istore luci-app-store || { echo "Failed to install luci-app-store."; exit 1; }


echo >> feeds.conf.default
echo 'src-git istore https://github.com/washsky/istore;washsky-patch-1' >> feeds.conf.default
./scripts/feeds update istore
./scripts/feeds install -d y -p istore luci-app-store






# 添加新的 feeds 并更新安装 nas 相关软件包
echo "Adding new feeds to feeds.conf.default..."
echo 'src-git nas https://github.com/linkease/nas-packages.git;master' >> "$OPENWRT_ROOT/feeds.conf.default"
echo 'src-git nas_luci https://github.com/linkease/nas-packages-luci.git;main' >> "$OPENWRT_ROOT/feeds.conf.default"

echo "Updating feeds..."
"$OPENWRT_ROOT/scripts/feeds" update nas nas_luci || { echo "Failed to update nas and nas_luci feeds."; exit 1; }

echo "Installing nas and nas_luci packages..."
"$OPENWRT_ROOT/scripts/feeds" install -a -p nas || { echo "Failed to install packages from nas feed."; exit 1; }
"$OPENWRT_ROOT/scripts/feeds" install -a -p nas_luci || { echo "Failed to install packages from nas_luci feed."; exit 1; }
