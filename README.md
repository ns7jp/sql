# SQL基礎演習案件パック

未経験からサーバー構築エンジニアを目指す学習者向けに作成した、**SQLの基礎を体系的に学べる演習パック**です。
架空のネットショップ運営会社のデータベースを題材に、`SELECT`の基本から、集計・結合・サブクエリ・
トランザクション・ビュー/インデックス/ウィンドウ関数まで、初心者が一人でも理解して進められるよう、
問題・ヒント・模範解答・解説をすべてセットにして構成しています。

## このリポジトリで示したいこと

サーバー構築エンジニアはSQLを書くだけでなく、**データベースサーバーを自分で構築・運用できること**も
求められます。そのため、このポートフォリオでは単なるSQL問題集ではなく、以下の3点をあわせて示しています。

- **SQLの体系的な理解**：基本文法から実務でよく使う応用（VIEW・INDEX・ウィンドウ関数）まで、
  段階を踏んで学べる構成にしていること
- **サーバー構築の実践**：Docker Composeで実際にMySQLサーバーを構築・起動し、
  手を動かして検証していること
- **わかりやすいドキュメント作成力**：初心者が迷わないよう、環境構築からER図、
  用語の早見表までドキュメントを整備していること

## 使用技術

| 分類 | 使用技術 |
|---|---|
| データベース | MySQL 8.0 |
| サーバー構築 | Docker / Docker Compose |
| ドキュメント | Markdown / Mermaid（ER図） |

## クイックスタート

```bash
git clone <このリポジトリのURL>
cd sql/docker
docker compose up -d
docker compose exec mysql mysql -u sql_user -psql_pass sql_exercise
```

詳しい手順・トラブルシューティングは [docs/00_setup.md](docs/00_setup.md) を参照してください。

## リポジトリ構成

```text
sql/
├── README.md                    … このファイル
├── docs/                        … ドキュメント
│   ├── 00_setup.md              … 環境構築ガイド（Docker Composeでの起動手順）
│   ├── 01_schema.md             … テーブル構造の解説とER図
│   ├── 02_how_to_use.md         … 演習の進め方・学習のコツ
│   └── 03_sql_cheatsheet.md     … SQL早見表（チートシート）
├── db/                          … データベース定義
│   ├── schema.sql                … テーブル定義（DDL）
│   └── seed_data.sql             … サンプルデータ（DML）
├── docker/
│   └── docker-compose.yml       … MySQLサーバー起動用の構成ファイル
└── exercises/                   … 演習問題（問題・ヒント・模範解答・解説）
    ├── level1_select_basics.md      … レベル1: SELECTの基本
    ├── level2_aggregate_groupby.md  … レベル2: 集計とグループ化
    ├── level3_join.md               … レベル3: テーブルの結合（JOIN）
    ├── level4_subquery.md           … レベル4: サブクエリ
    ├── level5_dml_transaction.md    … レベル5: データ操作とトランザクション
    └── level6_advanced.md           … レベル6: 実務でよく使う応用
```

## 学習の進め方

1. [docs/00_setup.md](docs/00_setup.md) の手順でMySQLサーバーを起動する
2. [docs/01_schema.md](docs/01_schema.md) でテーブル構造（ER図）を把握する
3. [docs/02_how_to_use.md](docs/02_how_to_use.md) を読み、演習の取り組み方を確認する
4. `exercises/level1_select_basics.md` から順番に演習を進める
5. 詰まったら [docs/03_sql_cheatsheet.md](docs/03_sql_cheatsheet.md) を見返す

各問題は、ヒントと模範解答を折りたたみ（`<details>`）で隠してあります。
まず自分で考えてSQLを書いてみてから答え合わせをする、という流れで進めてください。

## お題のデータベースについて

架空のネットショップ運営会社「サンプル商事」の社内データと受注データを題材にしています。

- 部署（departments）／社員（employees）
- 商品カテゴリ（categories）／商品（products）
- 顧客（customers）／注文（orders）／注文明細（order_items）

の7テーブルで構成されています。詳細は [docs/01_schema.md](docs/01_schema.md) を参照してください。

## ライセンス

[MIT License](LICENSE)
