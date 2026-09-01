# 00. 環境構築ガイド

このドキュメントでは、演習用のデータベース（MySQL 8.0）を手元のPCで動かす手順を説明します。
「サーバーを構築してデータベースを立ち上げる」こと自体も、このポートフォリオの学習内容の一部です。

## 前提条件

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)（Windows/Mac）または Docker Engine（Linux）がインストールされていること
- ターミナル（コマンドプロンプト / PowerShell / Terminal）が使えること

Dockerのインストールが完了しているか、次のコマンドで確認できます。

```bash
docker --version
docker compose version
```

バージョン情報が表示されればOKです。

## 1. データベースサーバーを起動する

リポジトリのルートで、以下のコマンドを実行します。

```bash
cd docker
docker compose up -d
```

初回起動時には、MySQLのイメージのダウンロードと初期化が行われるため、1〜2分ほどかかります。
`docker/`ディレクトリの `db/schema.sql` と `db/seed_data.sql` は、コンテナの初回起動時に
**ファイル名の昇順で自動的に実行**され、テーブル作成とサンプルデータの投入まで完了します。

起動状況は次のコマンドで確認できます。`STATUS` が `healthy` になれば準備完了です。

```bash
docker compose ps
```

## 2. データベースに接続する

Dockerコンテナに入っている `mysql` クライアントを使って、そのまま接続できます
（別途MySQLクライアントをインストールする必要はありません）。

```bash
docker compose exec mysql mysql -u sql_user -psql_pass sql_exercise
```

接続できたら、テーブルが作成されているか確認してみましょう。

```sql
SHOW TABLES;
SELECT * FROM employees;
```

7つのテーブル（departments, employees, categories, products, customers, orders, order_items）
と、それぞれにサンプルデータが表示されれば成功です。

MySQL Workbench や DBeaver、TablePlus などのGUIツールを使いたい場合は、以下の接続情報を使用してください。

| 項目 | 値 |
|---|---|
| ホスト | `127.0.0.1` |
| ポート | `3306` |
| ユーザー | `sql_user` |
| パスワード | `sql_pass` |
| データベース名 | `sql_exercise` |

## 3. サーバーを停止する

学習を終えたら、以下のコマンドでコンテナを停止できます（データは保持されます）。

```bash
docker compose down
```

再開したいときは、もう一度 `docker compose up -d` を実行するだけで、データが残った状態で
起動します。

## 4. データを最初の状態にリセットしたい場合

演習中にUPDATEやDELETEでデータを書き換えてしまい、まっさらな状態に戻したくなったら、
データ用のボリュームごと削除してから起動し直します。

```bash
docker compose down -v
docker compose up -d
```

`-v` オプションを付けると、`db/schema.sql` と `db/seed_data.sql` が再実行され、
最初のサンプルデータに戻ります。

## Dockerを使わない場合

すでにMySQLサーバーがローカルにインストールされている場合は、Dockerを使わなくても
以下のように直接流し込むことができます。

```bash
mysql -u root -p -e "CREATE DATABASE sql_exercise;"
mysql -u root -p sql_exercise < ../db/schema.sql
mysql -u root -p sql_exercise < ../db/seed_data.sql
```

## トラブルシューティング

| 症状 | 対処法 |
|---|---|
| `port is already allocated` と表示される | 手元のPCで既に3306番ポートが使われています。`docker/docker-compose.yml` の `ports` を `"13306:3306"` のように変更し、接続時のポート番号もあわせて変更してください |
| `docker compose exec` で接続できない | `docker compose ps` でコンテナが `healthy` になっているか確認してください。起動直後は初期化中の場合があります |
| データを編集しても `docker compose up -d` で元に戻らない | 初期化SQLはボリュームが空の状態でのみ実行されます。手順4の `down -v` でボリュームごと削除してから起動し直してください |

準備ができたら、[docs/01_schema.md](01_schema.md) でテーブル構造を確認し、
[docs/02_how_to_use.md](02_how_to_use.md) の進め方に沿って `exercises/` の演習を始めましょう。
