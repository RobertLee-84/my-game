#!/usr/bin/env bash
set -e

echo "=========================================================="
echo " 🚀 Retro DOS Web Arcade — GitHub 원클릭 배포 스크립트"
echo "=========================================================="

# 1. 배포용 폴더 구성
mkdir -p retro-dos-arcade/.github/workflows
mkdir -p retro-dos-arcade/games

if [ -f "retro_dos_web_arcade.html" ]; then
  cp retro_dos_web_arcade.html retro-dos-arcade/index.html
elif [ -f "index.html" ]; then
  cp index.html retro-dos-arcade/index.html
fi

cat << 'EOF' > retro-dos-arcade/.github/workflows/deploy.yml
name: Deploy Retro DOS Arcade to GitHub Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Configure Pages
        uses: actions/configure-pages@v5
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: '.'
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
EOF

cat << 'EOF' > retro-dos-arcade/games/README.md
# games 폴더
이곳에 fd2.zip(용의기사2), water2.zip(대항해시대2) 파일을 넣으면 서버에서 바로 로드됩니다.
EOF

# 현재 폴더에 fd2.zip 이나 water2.zip 이 있으면 자동으로 games/ 폴더로 복사
for z in fd2.zip water2.zip custom.zip; do
  if [ -f "$z" ]; then
    cp "$z" "retro-dos-arcade/games/$z"
    echo "✓ $z 파일을 retro-dos-arcade/games/ 폴더에 포함했습니다."
  fi
done

cd retro-dos-arcade

git init
git checkout -B main
git add .
git commit -m "feat: deploy Retro DOS Web Arcade (Flame Dragon 2 & Uncharted Waters 2)" || true

# 2. GitHub CLI(gh) 설치 여부 확인 후 자동 저장소 생성 & 푸시
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
  echo "✓ GitHub CLI 인증이 확인되어 자동으로 저장소를 생성하고 푸시합니다..."
  REPO_NAME="retro-dos-arcade"
  gh repo create "$REPO_NAME" --public --source=. --remote=origin --push || git push -u origin main
  GH_USER=$(gh api user -q .login)
  echo ""
  echo "🎉 배포 요청이 완료되었습니다!"
  echo "👉 저장소 주소: https://github.com/${GH_USER}/${REPO_NAME}"
  echo "👉 사이트 주소 (약 1분 후 활성화): https://${GH_USER}.github.io/${REPO_NAME}/"
else
  echo ""
  read -p "🔗 생성해 두신 GitHub 원격 저장소 주소(예: https://github.com/아이디/retro-dos-arcade.git)를 입력하세요: " REMOTE_URL
  if [ -n "$REMOTE_URL" ]; then
    git remote remove origin 2>/dev/null || true
    git remote add origin "$REMOTE_URL"
    git push -u origin main
    echo ""
    echo "🎉 GitHub 푸시가 완료되었습니다! 저장소 Settings -> Pages에서 Source를 'GitHub Actions' 또는 'main' 브랜치로 설정하면 바로 접속 가능합니다."
  else
    echo "⚠️ 원격 저장소 주소가 입력되지 않아 로컬 커밋까지만 완료했습니다."
  fi
fi
