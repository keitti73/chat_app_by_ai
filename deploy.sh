#!/bin/bash

# AWS AppSync Chat App デプロイスクリプト

set -e

echo "🚀 AWS AppSync Chat App をデプロイしています..."

# Terraformディレクトリに移動
cd infra

# terraform.tfvarsファイルが存在しない場合はサンプルをコピー
if [ ! -f terraform.tfvars ]; then
    echo "📝 terraform.tfvars ファイルを作成しています..."
    cp terraform.tfvars.example terraform.tfvars
    echo "⚠️  terraform.tfvars ファイルを確認して、必要に応じて設定を変更してください"
fi

# Terraform初期化
echo "🔧 Terraform を初期化しています..."
terraform init

# Terraform計画
echo "📋 Terraform 実行計画を確認しています..."
terraform plan

# ユーザー確認
read -p "上記の計画でデプロイを実行しますか？ (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Terraform適用
    echo "🚀 Terraform を適用しています..."
    terraform apply -auto-approve

    echo ""
    echo "✅ デプロイが完了しました!"
    echo ""
    echo "📄 以下の情報を src/App.jsx の amplifyConfig に設定してください:"
    echo ""
    terraform output amplify_config
    echo ""
    echo "🔑 API Key (機密情報):"
    terraform output -raw appsync_api_key
    echo ""
    echo ""
    echo "📖 詳細な手順については README.md を参照してください"
else
    echo "❌ デプロイがキャンセルされました"
    exit 1
fi
