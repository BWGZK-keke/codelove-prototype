#!/usr/bin/env bash
# 把站点文件发布到公开仓库 BWGZK-keke/codelove-prototype。
#
# 本仓库(codelove-prototype-src)是私有的,存放全部源码、测试、
# Firestore 规则和提交历史。公开仓库只存放浏览器真正需要的两个文件,
# 由 GitHub Pages 提供服务。
#
#   用法:./publish.sh ["提交说明"]
#
# 需要你本机的 git 已能推送到 BWGZK-keke/codelove-prototype。
set -euo pipefail

PUBLIC_REPO="git@github.com:BWGZK-keke/codelove-prototype.git"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${SRC_DIR}/.publish-checkout"

# 只发布这些文件 —— 站点真正需要的东西。其余一律留在私有仓库。
# 图标只发浏览器会请求的那几个:SVG 源码、生成脚本、iOS 那三张 1024
# 都留在私有仓库,公开仓库不需要。
FILES=(
  index.html
  # 约会地点库(REQ-034)。页面按需 fetch 它,少发一个,「约在哪」就只剩场景没有地点。
  places.json
  # 隐私政策和用户协议。App Store Connect 的隐私政策 URL 填的就是这两个页面,
  # iOS App 的「我的」页面也直接链过去 —— 少发一个,App 里就是死链。
  privacy.html
  terms.html
  # 行程分享页(REQ-036)。给紧急联系人看的,他们多半不是本站用户 ——
  # 少发这一个,一键分享出去的链接就是死链。
  trip.html
  # 字体切成两片 (REQ-044):core 谁打开都下,ext 只在页面出现生僻字时才下。
  # 少发 ext 的话,名字里带生僻字的人会看到那个字掉成系统字体。
  # 全站只有站酷快乐体一套 (REQ-088)。
  assets/zcool-core.woff2
  assets/zcool-ext.woff2
  assets/icon/favicon.svg
  assets/icon/favicon-32.png
  assets/icon/favicon-16.png
  assets/icon/apple-touch-icon.png
)

MSG="${1:-Publish site}"

for f in "${FILES[@]}"; do
  [[ -f "${SRC_DIR}/${f}" ]] || { echo "缺少文件:${f}" >&2; exit 1; }
done

if [[ -d "${WORK_DIR}/.git" ]]; then
  git -C "${WORK_DIR}" fetch --quiet origin main
  git -C "${WORK_DIR}" reset --quiet --hard origin/main
else
  rm -rf "${WORK_DIR}"
  git clone --quiet --depth 1 "${PUBLIC_REPO}" "${WORK_DIR}"
fi

for f in "${FILES[@]}"; do
  mkdir -p "${WORK_DIR}/$(dirname "${f}")"
  cp "${SRC_DIR}/${f}" "${WORK_DIR}/${f}"
done

# 先 add 再看暂存区。原先是先 `git diff` 再 add —— 那样只比对已跟踪的文件,
# 新增的文件在 diff 里是空的,会被判成「没有变化」直接 exit 0,
# 第一次加图标这种全新文件永远发不出去。
git -C "${WORK_DIR}" add -- "${FILES[@]}"

if git -C "${WORK_DIR}" diff --cached --quiet; then
  echo "站点内容没有变化,无需发布。"
  exit 0
fi

git -C "${WORK_DIR}" commit --quiet -m "${MSG}"
git -C "${WORK_DIR}" push --quiet origin main

echo "已发布 → https://bwgzk-keke.github.io/codelove-prototype/"
echo "(Pages 构建大约需要 1 分钟。)"
