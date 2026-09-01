# レベル6: 実務でよく使う応用（ビュー・インデックス・ウィンドウ関数）

> 🎯 このレベルで身につくこと
> - CASE式を使った条件分岐で、データにラベルを付けて見やすくする方法
> - よく使うJOINを「ビュー(VIEW)」として保存し、再利用する方法
> - インデックス(INDEX)の役割と、サーバー運用でなぜ重要なのかという考え方
> - ウィンドウ関数(ROW_NUMBER, RANK, SUM() OVER)を使った順位付け・累計計算
> - 日付関数を使った月次集計など、実務のレポート作成でよく使うテクニック

## 使用するテーブル
このレベルでは、`departments`（部署）・`employees`（社員）・`categories`（カテゴリ）・`products`（商品）・`customers`（顧客）・`orders`（注文）・`order_items`（注文明細）のすべてのテーブルを、目的に応じて組み合わせて使います。これまでのレベルで学んだJOINやGROUP BYを土台に、より実務に近い「集計レポート」や「運用視点」の問題に取り組みます。
テーブルの詳しい構造やリレーション（ER図）は [docs/01_schema.md](../docs/01_schema.md) を参照してください。

---

## 問題 1: CASE式で条件分岐する

**目的**: CASE式を使って、条件によって表示する値を分岐させる方法を学ぶ

**問題文**:
`products`（商品）テーブルから、商品名(`product_name`)と在庫数(`stock_quantity`)を取得し、さらに次のルールで在庫状況を判定した列(`stock_status`)を追加して表示してください。

- 在庫数が **0** の場合 →「在庫切れ」
- 在庫数が **1以上19以下** の場合 →「残りわずか」
- 在庫数が **20以上** の場合 →「在庫あり」

結果は在庫数が少ない順（昇順）に並べてください。

<details>
<summary>💡 ヒントを見る</summary>

- CASE式は `CASE WHEN 条件1 THEN 値1 WHEN 条件2 THEN 値2 ELSE 値3 END` という書き方をします。
- `WHEN`句は上から順番に判定され、最初に条件に一致したものが採用されます（IF文の「else if」と同じ考え方です）。
- CASE式の結果にも `AS` で別名をつけられます。
- `ORDER BY 列名 ASC` で昇順に並び替えます（`ASC`は省略しても昇順になります）。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    product_name,
    stock_quantity,
    CASE
        WHEN stock_quantity = 0 THEN '在庫切れ'
        WHEN stock_quantity < 20 THEN '残りわずか'
        ELSE '在庫あり'
    END AS stock_status
FROM products
ORDER BY stock_quantity ASC;
```

**実行結果イメージ**:

```text
product_name       | stock_quantity | stock_status
-------------------+----------------+--------------
折りたたみ傘        | 0              | 在庫切れ
デジタルカメラ      | 8              | 残りわずか
レディースバッグ    | 12             | 残りわずか
ノートパソコン      | 15             | 残りわずか
プログラミング雑誌  | 20             | 在庫あり
電気ケトル          | 25             | 在庫あり
...(全16件)
```

**解説**:
CASE式は「もし〜ならA、そうでなければB」という条件分岐をSQLの中で表現できる構文です。`WHEN`は上から順に評価されるため、書く順番が重要になります。ここでは先に「0かどうか」を判定し、次に「20未満かどうか」を判定しています。もし順番を逆にして「20未満」を先に書くと、在庫0の商品も「残りわずか」に分類されてしまい正しく判定できません。最後の`ELSE`は、それまでのどの条件にも当てはまらなかった場合の受け皿で、書かないとNULLになってしまうので基本的には用意しておきます。

**覚え方のポイント**:
CASE式は「テーブルの値そのものは変えずに、表示上だけラベルを付け替える」機能だと覚えると理解しやすいです。実務では、注文ステータスの日本語表示や、売上金額の大小によるランク分けなど、集計レポートの見やすさを上げる目的でよく使われます。条件が多くなる場合は、範囲の狭い条件（境界値に近いもの）から先に書く癖をつけると、判定ミスを防げます。

</details>

---

## 問題 2: VIEWを作る

**目的**: よく使うJOINを「ビュー(VIEW)」として保存し、毎回同じJOINを書かずに再利用する方法を学ぶ

**問題文**:
注文一覧を確認するとき、`orders`テーブルだけでは「どの顧客の注文か」「誰が対応した注文か」が社員名・顧客名としてわかりません。そこで、`orders`・`customers`・`employees`を結合し、注文ID(`order_id`)・顧客名(`customer_name`)・対応社員名(`employee_name`)・注文日(`order_date`)・ステータス(`status`)をまとめて見られる**ビュー**を`order_summary_view`という名前で作成してください。

なお、`orders.employee_id`はWebサイトからの直接注文の場合に`NULL`になることがあるため、対応社員がいない注文でも結果から消えないように結合してください（対応社員名は`NULL`のまま表示されればOKです）。

<details>
<summary>💡 ヒントを見る</summary>

- ビューを作るには `CREATE VIEW ビュー名 AS SELECT ...` という構文を使います。
- 作り直しでエラーにならないようにするには `CREATE OR REPLACE VIEW` を使うと安全です。
- 「対応社員がいない注文も残す」ということは、`employees`との結合はどのJOINを使うべきか考えましょう（レベル4で学んだ内容です）。
- ビューは一度作れば、あとは普通のテーブルのように `SELECT * FROM ビュー名;` で使えます。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
CREATE OR REPLACE VIEW order_summary_view AS
SELECT
    o.order_id,
    c.customer_name,
    e.employee_name,
    o.order_date,
    o.status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN employees e ON o.employee_id = e.employee_id;
```

**実行結果イメージ**:

ビュー自体を作成するSQLなので、実行しても行は返ってきません。作成後に `SELECT * FROM order_summary_view ORDER BY order_id;` を実行すると、次のような結果が見られます。

```text
order_id | customer_name | employee_name | order_date | status
---------+----------------+---------------+------------+-----------
1        | 中山 陽子      | 田中 三郎     | 2023-01-05 | 完了
2        | 木村 健一      | NULL          | 2023-01-08 | 完了
3        | 林 美穂        | 伊藤 陽子     | 2023-01-12 | 完了
4        | 中山 陽子      | NULL          | 2023-01-20 | キャンセル
5        | 清水 大輔      | 田中 三郎     | 2023-02-02 | 完了
...(全18件)
```

**解説**:
`CREATE VIEW`は、SELECT文に名前を付けて保存しておく仕組みです。ビューそのものにはデータは入っておらず、実行するたびに元になったSELECT文が実行されて結果が返されます。そのため、`orders`や`customers`のデータが更新されれば、ビューを参照した結果にもすぐ反映されます。ここでは、対応社員がいない注文（`employee_id`が`NULL`）も結果から消したくないため、`employees`との結合には`INNER JOIN`ではなく`LEFT JOIN`を使っています。`INNER JOIN`にしてしまうと、`employee_id`が`NULL`の注文（Webサイトからの直接注文）がすべて結果から消えてしまうので注意が必要です。

**覚え方のポイント**:
ビューは「よく使う複雑なJOINに名前を付けて、簡単に呼び出せるようにする引き出し」だとイメージすると覚えやすいです。実務では、複数のテーブルを毎回JOINして書くのは手間もミスも増えるため、ダッシュボードやレポートでよく使う集計・結合をビュー化しておくことがよくあります。ただし、ビューはあくまで「保存されたSELECT文」であり、元のテーブルより検索が速くなるわけではない点は覚えておきましょう。

</details>

---

## 問題 3: INDEXの基本

**目的**: なぜインデックスが必要なのか、`CREATE INDEX`の基本的な書き方を学ぶ

**問題文**:
ECサイトのログイン処理では、`customers`テーブルに対して`WHERE email = '...'`のような検索が非常に高い頻度で実行されます。テーブルの件数が少ないうちは問題になりませんが、サーバー運用エンジニアとしては、データが数百万件に増えたときに検索が遅くならないよう、あらかじめ備えておく必要があります。
`customers`テーブルの`email`列に対して、検索を高速化するためのインデックスを`idx_customers_email`という名前で作成してください。

<details>
<summary>💡 ヒントを見る</summary>

- インデックスを作る構文は `CREATE INDEX インデックス名 ON テーブル名 (列名);` です。
- インデックスは「本の索引」と同じ役割で、対象の列でよく検索・絞り込み・並び替えをする場合に効果を発揮します。
- 主キー(`PRIMARY KEY`)には自動でインデックスが作られますが、それ以外のよく検索に使う列には自分でインデックスを追加する必要があります。
- インデックスを作りすぎると、データの追加・更新（INSERT/UPDATE）が遅くなるというデメリットもあります。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
CREATE INDEX idx_customers_email ON customers (email);
```

**実行結果イメージ**:

インデックスの作成もビューと同様、行を返すSQLではありません。作成後に `SHOW INDEX FROM customers;` を実行すると、インデックスが登録されたことを確認できます。

```text
Table     | Key_name              | Column_name | Non_unique
----------+-----------------------+-------------+------------
customers | PRIMARY               | customer_id | 0
customers | idx_customers_email   | email       | 1
```

**解説**:
インデックスがない状態で`WHERE email = '...'`を実行すると、データベースはテーブルの先頭行から1件ずつ全件チェックする「フルテーブルスキャン」を行います。件数が少なければ一瞬ですが、件数が数百万件に増えると検索に何秒もかかるようになり、Webサービスとしては致命的な遅さになります。インデックスを作成すると、データベースは本の索引のように「値→どの行にあるか」を整理した構造をあらかじめ用意しておき、検索時にその索引を辿ることで、目的の行を素早く見つけられるようになります。ただし、インデックスは万能ではなく、INSERTやUPDATEのたびに索引側も更新する必要があるため、書き込み性能とのトレードオフになります。

**覚え方のポイント**:
「検索・絞り込み・JOINの条件・ORDER BYでよく使う列にはインデックスを検討する」「更新頻度が高すぎる列やカーディナリティ（値の種類）が低い列には向かない」という2点をセットで覚えておくと実務で役立ちます。サーバー構築エンジニアとしては、アプリケーションのSQLログを見て「WHERE句やJOIN条件でよく使われている列」を洗い出し、インデックス設計を検討する視点が重要です。

</details>

---

## 問題 4: ウィンドウ関数入門 — ROW_NUMBER() と RANK() の違い

**目的**: ウィンドウ関数の基本である`ROW_NUMBER()`と`RANK()`の違いを理解する

**問題文**:
`products`テーブルから、商品名(`product_name`)と価格(`price`)を取得し、価格が高い順に、次の2種類の連番を付けて表示してください。

- `ROW_NUMBER()`を使った連番 → `row_num`
- `RANK()`を使った順位 → `rank_num`

結果は価格が高い順に並べてください。

<details>
<summary>💡 ヒントを見る</summary>

- ウィンドウ関数は `関数名() OVER (ORDER BY 列名 DESC)` という書き方をします。
- `ROW_NUMBER()`は同じ値でも必ず1つずつ違う連番を振ります。
- `RANK()`は同じ値には同じ順位を振り、その次の順位は同着の人数分スキップされます（例：1位が2人いたら次は3位）。
- MySQLでウィンドウ関数が使えるのはバージョン8.0以降です。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    product_name,
    price,
    ROW_NUMBER() OVER (ORDER BY price DESC) AS row_num,
    RANK() OVER (ORDER BY price DESC) AS rank_num
FROM products
ORDER BY price DESC;
```

**実行結果イメージ**:

```text
product_name           | price | row_num | rank_num
------------------------+-------+---------+----------
ノートパソコン          | 89800 | 1       | 1
デジタルカメラ          | 45800 | 2       | 2
ワイヤレスイヤホン      | 12800 | 3       | 3
レディースバッグ        | 8900  | 4       | 4
...
オリーブオイル          | 980   | 11      | 11
プログラミング雑誌      | 980   | 12      | 11
電卓                    | 780   | 13      | 13
...(全16件)
```

**解説**:
`ROW_NUMBER()`と`RANK()`はどちらも「順位・連番を振る」ウィンドウ関数ですが、同じ値が並んだときの挙動が異なります。今回のデータでは、オリーブオイルとプログラミング雑誌がどちらも980円で同額です。`ROW_NUMBER()`はこの同額のペアにも11・12という別々の連番を振りますが、`RANK()`はどちらも同じ11位とし、その次の電卓は12位ではなく13位（11位が2件あった分をスキップ）になります。このように、単に「上から何番目か」を知りたいだけなら`ROW_NUMBER()`、「同点は同じ順位として扱いたい」場合は`RANK()`を使う、という使い分けが基本です。

**覚え方のポイント**:
「同着を許すかどうか」で覚えると迷いません。ランキング表示のように同点を同じ順位として見せたいときは`RANK()`（またはランクを飛ばさない`DENSE_RANK()`）、ページネーションのように必ず一意な番号が欲しいときは`ROW_NUMBER()`を使います。GROUP BYと違い、ウィンドウ関数は集計してもそれぞれの行を残せる点が大きな特徴です。

</details>

---

## 問題 5: PARTITION BYでグループごとに順位付け — 部署内の給与順位

**目的**: `PARTITION BY`を使って、グループ（部署）ごとに独立した順位付けを行う方法を学ぶ

**問題文**:
`employees`テーブルと`departments`テーブルを結合し、部署名(`department_name`)・社員名(`employee_name`)・給与(`salary`)に加えて、**同じ部署の中で**給与が高い順に何位かを示す列(`salary_rank`)を表示してください。結果は部署ID順、同じ部署の中では順位が高い順に並べてください。

<details>
<summary>💡 ヒントを見る</summary>

- `PARTITION BY 列名`を`OVER`の中に追加すると、指定した列の値が同じ行同士でグループを作り、そのグループ内だけで順位を計算できます。
- 書き方は `RANK() OVER (PARTITION BY 列名 ORDER BY 列名 DESC)` です。
- GROUP BYと違い、集計してもグループ内の1件1件の行がそのまま残ります。
- ORDER BYには複数の列（部署ID、順位など）を指定できます。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    d.department_name,
    e.employee_name,
    e.salary,
    RANK() OVER (PARTITION BY e.department_id ORDER BY e.salary DESC) AS salary_rank
FROM employees e
JOIN departments d ON e.department_id = d.department_id
ORDER BY e.department_id, salary_rank;
```

**実行結果イメージ**:

```text
department_name | employee_name | salary  | salary_rank
-----------------+----------------+---------+-------------
営業部           | 山田 太郎      | 650000  | 1
営業部           | 高橋 次郎      | 520000  | 2
営業部           | 田中 三郎      | 380000  | 3
営業部           | 伊藤 陽子      | 360000  | 4
開発部           | 佐藤 花子      | 680000  | 1
開発部           | 渡辺 健太      | 540000  | 2
開発部           | 中村 美咲      | 450000  | 3
開発部           | 小林 大輔      | 350000  | 4
総務部           | 鈴木 一郎      | 600000  | 1
総務部           | 山本 さくら    | 340000  | 2
マーケティング部 | 加藤 綾        | 500000  | 1
マーケティング部 | 吉田 拓也      | 370000  | 2
```

**解説**:
`PARTITION BY e.department_id`を指定することで、「部署ごとに区切って、その中だけで順位を数え直す」という計算になります。もし`PARTITION BY`を付けずに`RANK() OVER (ORDER BY salary DESC)`だけを書くと、会社全体での順位（問題4のような1本のランキング）になってしまい、「部署内で何番目か」は求められません。`PARTITION BY`は`GROUP BY`と似たイメージを持つ人が多いですが、`GROUP BY`は行を集約して件数を減らすのに対し、`PARTITION BY`は行数を減らさずにグループ単位の計算結果だけを追加できる点が大きな違いです。

**覚え方のポイント**:
「`PARTITION BY`はウィンドウ関数専用のGROUP BYのようなもの、ただし行は減らない」と覚えると理解しやすいです。実務では「部署ごとの給与ランキング」「カテゴリごとの売れ筋商品」「顧客ごとの直近注文」のように、"全体"ではなく"グループの中"での順位や比較をしたい場面で頻繁に使われます。

</details>

---

## 問題 6: 累計・移動集計 — SUM() OVER(ORDER BY ...) で累計売上を出す

**目的**: ウィンドウ関数の`SUM() OVER (ORDER BY ...)`を使って、日付順の累計値（ランニングトータル）を計算する方法を学ぶ

**問題文**:
`orders`と`order_items`を使って、注文ごとの売上金額（数量×単価の合計）を計算してください。ただし、ステータス(`status`)が「キャンセル」の注文は売上に含めないでください。
そのうえで、注文日(`order_date`)が古い順に並べながら、その注文日までの**累計売上金額**(`running_total`)を表示してください。表示する列は、注文日(`order_date`)・その注文の売上金額(`order_total`)・累計売上金額(`running_total`)の3つです。

<details>
<summary>💡 ヒントを見る</summary>

- まずサブクエリで、注文ごとの合計金額（`SUM(quantity * unit_price)`）を`order_id`ごとに計算します。
- サブクエリの結果に対して、`SUM(order_total) OVER (ORDER BY order_date)`を使うと、その時点までの累計を計算できます。
- キャンセルの除外は、サブクエリの中の`WHERE`句で行います。
- サブクエリには`FROM (SELECT ...) AS 別名`のように別名を付ける必要があります。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    sub.order_date,
    sub.order_total,
    SUM(sub.order_total) OVER (ORDER BY sub.order_date) AS running_total
FROM (
    SELECT
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price) AS order_total
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status <> 'キャンセル'
    GROUP BY o.order_id, o.order_date
) AS sub
ORDER BY sub.order_date;
```

**実行結果イメージ**:

```text
order_date | order_total | running_total
-----------+-------------+---------------
2023-01-05 | 90800       | 90800
2023-01-08 | 3600        | 94400
2023-01-12 | 4300        | 98700
2023-02-02 | 5960        | 104660
2023-02-10 | 5360        | 110020
...
2023-05-22 | 2410        | 384420
```
（キャンセルされた注文2件を除いた、全16件が表示されます）

**解説**:
このSQLは2段階で組み立てられています。まず内側のサブクエリで、`orders`と`order_items`を結合し、キャンセルされた注文を除いたうえで、注文1件ごとの売上金額を`GROUP BY`で計算しています。次に外側のクエリで、そのサブクエリの結果に対して`SUM(order_total) OVER (ORDER BY order_date)`を適用し、「注文日が古いものから、その行までの合計」を計算しています。ポイントは、`SUM() OVER`に`PARTITION BY`を付けず`ORDER BY`だけを指定すると、既定の動作として「先頭からその行までの累計」が計算されることです。通常の`SUM()`を`GROUP BY`と組み合わせると1つの合計値にまとまってしまいますが、ウィンドウ関数なら1行ごとに累計の途中経過を残せます。

**覚え方のポイント**:
累計・移動平均・前日比などの「時系列の分析」は、`GROUP BY`では実現できず、ウィンドウ関数の`ORDER BY`付きの集計関数が得意とする領域です。「集計してから、その集計結果に対してさらにウィンドウ関数をかける」という2段階構成は実務のレポートSQLで非常によく登場するパターンなので、この形をひな形として覚えておくと応用が効きます。

</details>

---

## 問題 7: 日付を扱う — 登録月ごとの新規顧客数を集計する

**目的**: MySQLの日付関数（`YEAR()`, `MONTH()`など）を使って、日付データを年月単位で集計する方法を学ぶ

**問題文**:
`customers`テーブルの会員登録日(`registered_date`)をもとに、年(`reg_year`)・月(`reg_month`)ごとの新規登録顧客数(`new_customer_count`)を集計してください。結果は年月が古い順に並べてください。

<details>
<summary>💡 ヒントを見る</summary>

- `YEAR(列名)`で日付から年だけ、`MONTH(列名)`で月だけを取り出せます。
- `GROUP BY`には、集計の基準にしたい列（ここでは年と月）をすべて指定します。
- 件数を数えるには`COUNT(*)`を使います。
- `YEAR()`や`MONTH()`、`DATE_FORMAT()`はMySQL独自の日付関数です（他のDB製品では書き方が異なる場合があります）。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    YEAR(registered_date) AS reg_year,
    MONTH(registered_date) AS reg_month,
    COUNT(*) AS new_customer_count
FROM customers
GROUP BY YEAR(registered_date), MONTH(registered_date)
ORDER BY reg_year, reg_month;
```

**実行結果イメージ**:

```text
reg_year | reg_month | new_customer_count
---------+-----------+---------------------
2022     | 1         | 1
2022     | 2         | 1
2022     | 3         | 1
2022     | 4         | 1
...
2023     | 1         | 1
2023     | 2         | 1
```
（このサンプルデータでは登録日がすべて別々の月なので、各月の件数は1件ずつになります。実際の運用データでは、同じ月に複数人が登録して2件以上になることもあります）

**解説**:
`YEAR()`と`MONTH()`はどちらもMySQLが提供している日付関数で、`DATE`型や`DATETIME`型の列から年・月の数値だけを取り出せます。`GROUP BY`に`YEAR(registered_date), MONTH(registered_date)`を指定することで、「同じ年かつ同じ月」の行同士をひとまとめにして件数を数えられます。もし`GROUP BY registered_date`のように日付そのものでグループ化してしまうと、日付が1日でも違えば別グループとして扱われてしまい、月単位の集計にはなりません。年月をまとめて扱いたい場合、`DATE_FORMAT(registered_date, '%Y-%m')`のように1つの文字列にしてから`GROUP BY`する書き方もよく使われます。

**覚え方のポイント**:
日付を「年」「月」「日」といった単位に分解して集計したいときは、まず「何の単位でグループ化したいか」を先に決め、それに対応する関数（`YEAR()`、`MONTH()`、`DATE_FORMAT()`など）を選ぶ、という順番で考えると迷いません。月次レポートや日次アクセス集計など、実務のダッシュボードでは日付の単位変換が非常によく使われます。

</details>

---

## 問題 8: 総合問題 — 顧客別の売上ランキングレポート

**目的**: JOIN・GROUP BY・集計関数・ウィンドウ関数(RANK)を組み合わせて、実務レベルの集計レポートを作る力を身につける

**問題文**:
`customers`・`orders`・`order_items`を使って、顧客ごとの売上ランキングレポートを作成してください。

- 顧客名(`customer_name`)ごとに、売上金額の合計(`total_sales`、数量×単価の合計)を計算する
- ただし、ステータスが「キャンセル」の注文は売上に含めない
- 売上金額が高い順に順位(`sales_rank`)を付ける（同額の場合は同じ順位でよい）
- 結果は順位が高い順に並べる

<details>
<summary>💡 ヒントを見る</summary>

- `customers`・`orders`・`order_items`の3つを、それぞれの外部キーでJOINします。
- `WHERE`でキャンセルの注文を除外するのを忘れないようにしましょう。
- `GROUP BY`で顧客ごとにまとめ、`SUM(quantity * unit_price)`で売上合計を計算します。
- 順位付けには`RANK() OVER (ORDER BY 集計結果 DESC)`を使います。集計関数とウィンドウ関数は同じSELECT文の中で一緒に使えます。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    c.customer_name,
    SUM(oi.quantity * oi.unit_price) AS total_sales,
    RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS sales_rank
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status <> 'キャンセル'
GROUP BY c.customer_id, c.customer_name
ORDER BY sales_rank;
```

**実行結果イメージ**:

```text
customer_name | total_sales | sales_rank
---------------+-------------+------------
中山 陽子      | 116400      | 1
木村 健一      | 97320       | 2
清水 大輔      | 96260       | 3
前田 さくら    | 45800       | 4
林 美穂        | 9280        | 5
森田 由紀      | 7340        | 6
松本 蓮        | 4500        | 7
石田 健太      | 3760        | 8
藤田 愛        | 3760        | 8
```

**解説**:
このSQLは、これまでのレベルで学んだJOINとGROUP BYによる集計に、`RANK()`ウィンドウ関数を組み合わせた総合問題です。まず3つのテーブルをJOINして注文明細レベルの行を作り、`WHERE`でキャンセル分を除外し、`GROUP BY c.customer_id, c.customer_name`で顧客ごとに売上を合計します。最後に、その合計結果に対して`RANK() OVER (ORDER BY SUM(...) DESC)`を適用することで、集計と同時に順位付けができます。結果を見ると、石田健太さんと藤田愛さんの売上がどちらも3,760円で同額のため、`RANK()`によって同じ8位が付いています（次の順位は9位ではなく10位から、という点は問題4で学んだ通りです）。また、注文がすべてキャンセルだった顧客や、一度も注文していない顧客は`JOIN`の時点で結果から自然に除外されている点にも注目してください。

**覚え方のポイント**:
実務のレポートSQLの多くは「JOINでデータをつなげる → WHEREで対象を絞る → GROUP BYで集計する → 必要ならウィンドウ関数で順位や累計を付ける」という流れで組み立てられます。この順番をテンプレートとして覚えておくと、「〇〇別の売上ランキング」「〇〇ごとのトップ3」といった実務でよくある依頼にも、落ち着いて対応できるようになります。

</details>

---

## この章のまとめ
- CASE式を使うと、条件によって表示するラベルを分岐させ、データを見やすく整形できる
- CREATE VIEWでよく使うJOINを保存しておけば、複雑な結合を毎回書かずに再利用できる
- インデックスは検索を高速化する仕組みだが、更新性能とのトレードオフがあり、サーバー運用の視点での設計判断が必要になる
- ROW_NUMBER()とRANK()は似ているが、同着（同じ値）の扱い方が異なる
- PARTITION BYを使うと、GROUP BYのように行を減らすことなく、グループ単位の順位や集計を計算できる
- SUM() OVER (ORDER BY ...)を使えば、累計売上のような時系列の集計をGROUP BYなしで計算できる
- YEAR()やMONTH()、DATE_FORMAT()などのMySQLの日付関数を使えば、日付データを年月単位で柔軟に集計できる
- JOIN → WHERE → GROUP BY → ウィンドウ関数、という流れは実務レポートSQLの基本パターンとして覚えておくと応用が効く

ここまでで、SQLの基礎から実務でよく使う応用構文まで一通り学びました。次のレベルでは、トランザクションやパフォーマンスチューニングなど、さらに実務・運用に近いテーマに取り組んでいきましょう。
