# .NET 8 SDK イメージを使用
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# 作業ディレクトリを設定
WORKDIR /app

# ビルド引数として認証情報を受け取る
ARG GITHUB_USERNAME
ARG GITHUB_TOKEN


# GitHub NuGetソースを追加（認証情報付き）
RUN dotnet nuget add source https://nuget.pkg.github.com/NagasakaH/index.json \
    --name github \
    --username ${GITHUB_USERNAME} \
    --password ${GITHUB_TOKEN} \
    --store-password-in-clear-text

# GitHubソースからもインストールを試行（フォールバック）
RUN dotnet tool install --global HelloWorldTool --add-source github
RUN dotnet tool install --global KonichiwaTool --add-source github

# ランタイムイメージ
FROM mcr.microsoft.com/dotnet/runtime:8.0

# .NET toolsのパスを設定
ENV PATH="${PATH}:/root/.dotnet/tools"

# 前のステージからツールをコピー
COPY --from=build /root/.dotnet /root/.dotnet

# 動作確認用のスクリプトを作成
RUN echo '#!/bin/bash\n\
echo "=== Available Tools ==="\n\
dotnet tool list --global\n\
echo ""\n\
echo "=== HelloWorldTool ==="\n\
hello-world-tool || echo "HelloWorldTool not found"\n\
echo ""\n\
echo "=== KonichiwaTool ==="\n\
konichiwa-tool || echo "KonichiwaTool not found"\n\
echo ""\n\
echo "Tools are ready to use!"\n\
' > /usr/local/bin/test-tools.sh && chmod +x /usr/local/bin/test-tools.sh

# デフォルトコマンド
CMD ["/usr/local/bin/test-tools.sh"]
