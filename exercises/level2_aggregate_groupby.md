# レベル2: 集計とグループ化

> 🎯 このレベルで身につくこと
> - `COUNT` / `SUM` / `AVG` / `MAX` / `MIN` などの集計関数の使い方
> - `GROUP BY` でデータをグループ単位に分けて集計する方法
> - `HAVING` でグループを絞り込む方法と、`WHERE` との違い
> - `WHERE` → `GROUP BY` → `HAVING` という実行順序の考え方
> - `quantity * unit_price` のように計算した値を集計して、売上金額のような実務指標を求める方法

## 使用するテーブル

このレベルでは、社員情報を持つ `employees`、商品情報を持つ `products`、注文明細を持つ `order_items` を中心に使います。`order_items` は1つの注文に対して複数の商品明細がぶら下がる「明細テーブル」で、`quantity`（数量）と `unit_price`（注文時点の単価）を持っているため、売上金額の集計によく使われます。詳しいER図は [docs/01_schema.md](../docs/01_schema.md) を参照してください。

---

## 問題 1: 件数を数える — COUNT(*) と COUNT(列) の違い

**目的**: `COUNT(*)` と `COUNT(列名)` の違い（NULLの扱い方の違い）を理解する

**問題文**:
`employees`（社員）テーブルから、次の2つの値を1つのSELECT文で取得してください。

- 社員の総人数（`total_employees`という列名で）
- 上司がいる社員の人数（`employees_with_manager`という列名で）

ヒント: `manager_id`（上司の社員ID）は、部長クラスの社員では上司がいないため NULL になっています。

<details>
<summary>💡 ヒントを見る</summary>

- `COUNT(*)` は行そのものの数を数えるので、NULLがあっても関係なくすべての行を数えます。
- `COUNT(列名)` はその列の値がNULLでない行だけを数えます。
- 列に別名をつけるには `AS 別名` を使います。
- 1つのSELECT文の中に、集計関数は複数書くことができます。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    COUNT(*) AS total_employees,
    COUNT(manager_id) AS employees_with_manager
FROM employees;
```

**実行結果イメージ**:

```text
total_employees | employees_with_manager
-----------------+-------------------------
              12 |                       8
```

**解説**:
`employees` テーブルには社員が12人いますが、そのうち山田・佐藤・鈴木・加藤の4人は部長クラスで上司がいないため、`manager_id` が NULL になっています。`COUNT(*)` は「行が存在するかどうか」だけを見るため、NULLを含んでいても12行すべてを数えます。一方 `COUNT(manager_id)` は「`manager_id` の値がNULLでない行」だけを数えるため、12から4を引いた8になります。このように、同じ集計関数でも `*` を指定するか列名を指定するかで結果が変わる点が、初心者が最初につまずきやすいポイントです。

**覚え方のポイント**:
「`COUNT(*)` は人数（行数）そのもの、`COUNT(列)` はその列にちゃんと値が入っている人数」とセットで覚えましょう。実務では「メールアドレス未登録の顧客を除いた件数」のように、NULLを除外して数えたい場面で `COUNT(列)` が活躍します。

</details>

---

## 問題 2: 合計・平均・最大・最小 — SUM / AVG / MAX / MIN

**目的**: `SUM`・`AVG`・`MAX`・`MIN` という代表的な集計関数の使い方を覚える

**問題文**:
`employees`（社員）テーブルの `salary`（給与）列を使って、次の4つの値を1つのSELECT文で取得してください。

- 給与の合計（`total_salary`）
- 給与の平均（`avg_salary`、小数点以下は四捨五入して整数にする）
- 給与の最大値（`max_salary`）
- 給与の最小値（`min_salary`）

<details>
<summary>💡 ヒントを見る</summary>

- 合計は `SUM()`、平均は `AVG()`、最大値は `MAX()`、最小値は `MIN()` を使います。
- 平均を四捨五入するには `ROUND(AVG(salary))` のように `ROUND()` 関数で包みます。
- 集計関数は複数まとめて1つのSELECT文に書けます。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    SUM(salary) AS total_salary,
    ROUND(AVG(salary)) AS avg_salary,
    MAX(salary) AS max_salary,
    MIN(salary) AS min_salary
FROM employees;
```

**実行結果イメージ**:

```text
total_salary | avg_salary | max_salary | min_salary
--------------+------------+------------+------------
     5740000 |     478333 |     680000 |     340000
```

**解説**:
`SUM`・`AVG`・`MAX`・`MIN` はどれも「複数行の値をまとめて1つの値にする」集計関数です。12人分の `salary` を合計すると5,740,000円になり、それを12人で割った平均は478,333円になります（割り切れないため `ROUND()` で四捨五入しています）。最大値は佐藤花子部長の680,000円、最小値は山本さくらさんの340,000円です。集計関数を使うと、1件ずつ確認しなくても表全体の傾向を一瞬で把握できるのが最大のメリットです。

**覚え方のポイント**:
`SUM`=合計、`AVG`=Average（平均）、`MAX`=最大、`MIN`=最小と、英単語の意味そのままなので覚えやすいです。給与や売上のような数値列に対してよく使うので、「数字の列を見たらこの4兄弟を思い出す」くらいの感覚で身につけましょう。

</details>

---

## 問題 3: グループごとに集計する — GROUP BYの基本

**目的**: `GROUP BY` を使って、行をグループ分けしてから集計する方法を理解する

**問題文**:
`employees`（社員）テーブルから、部署ID（`department_id`）ごとの社員数を求めてください。列名は `department_id` と `employee_count` にし、`department_id` の昇順で並べてください。

<details>
<summary>💡 ヒントを見る</summary>

- 「〇〇ごとに集計する」と言われたら `GROUP BY 〇〇` を使います。
- SELECT句には、`GROUP BY` で指定した列と、集計関数（この場合は `COUNT(*)`）だけを書きます。
- 並び順を指定するには `ORDER BY` を使います。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
ORDER BY department_id;
```

**実行結果イメージ**:

```text
department_id | employee_count
---------------+-----------------
             1 |               4
             2 |               4
             3 |               2
             4 |               2
```

**解説**:
`GROUP BY department_id` を指定すると、MySQLは `department_id` の値が同じ行同士を1つのグループにまとめます。そして `COUNT(*)` は「グループ全体の行数」ではなく「そのグループの中の行数」を数えるようになります。営業部（department_id=1）と開発部（department_id=2）にはそれぞれ4人、総務部（3）とマーケティング部（4）にはそれぞれ2人の社員がいることが分かります。`GROUP BY` を使うSELECT文では、SELECT句に書けるのは「`GROUP BY` で指定した列」と「集計関数の結果」だけというルールがある点に注意してください。

**覚え方のポイント**:
「`GROUP BY` は表をいくつかの小さなグループに切り分ける操作、集計関数はその小さなグループそれぞれに対して計算する」とイメージすると理解しやすいです。「部署ごとに」「日付ごとに」「カテゴリごとに」という日本語が出てきたら `GROUP BY` のサインだと覚えましょう。

</details>

---

## 問題 4: グループを絞り込む — HAVING

**目的**: 集計した後のグループを絞り込む `HAVING` の使い方と、`WHERE` との違いを理解する

**問題文**:
`employees`（社員）テーブルから、所属する社員数が3人以上の部署だけを抽出してください。列名は `department_id` と `employee_count` にし、`department_id` の昇順で並べてください。

<details>
<summary>💡 ヒントを見る</summary>

- 「集計した後の結果」に対して条件をつけたいときは `WHERE` ではなく `HAVING` を使います。
- `HAVING` は `GROUP BY` の後ろに書きます。
- `HAVING COUNT(*) >= 3` のように、集計関数をそのまま条件式に書けます。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department_id
HAVING COUNT(*) >= 3
ORDER BY department_id;
```

**実行結果イメージ**:

```text
department_id | employee_count
---------------+-----------------
             1 |               4
             2 |               4
```

**解説**:
`WHERE` は「集計する前の、1行ずつの生データ」に対する条件です。それに対して `HAVING` は「`GROUP BY` でグループ化して集計した後の結果」に対する条件です。今回は「社員数が3人以上」という条件が `COUNT(*)` という集計結果そのものに対する条件なので、`WHERE` では書けず `HAVING` を使う必要があります。実際、`WHERE department_id ...` のように書いても「社員数」という集計結果はまだ存在していないため使えません。総務部（2人）とマーケティング部（2人）は3人未満なので除外され、営業部と開発部（どちらも4人）だけが残ります。

**覚え方のポイント**:
「`WHERE` は集計する前のフィルター、`HAVING` は集計した後のフィルター」と覚えましょう。目安として、条件の中に `COUNT`・`SUM`・`AVG` などの集計関数が出てくるなら `HAVING`、出てこないなら `WHERE` と判断すればほぼ間違いありません。

</details>

---

## 問題 5: 複数キーでグループ化 — GROUP BY 複数列

**目的**: 2つ以上の列を組み合わせて `GROUP BY` する方法を理解する

**問題文**:
`products`（商品）テーブルから、カテゴリID（`category_id`）ごと、かつ「在庫あり」か「在庫切れ」（在庫状況）ごとに商品数を求めてください。在庫状況は、`stock_quantity`（在庫数）が0なら「在庫切れ」、それ以外は「在庫あり」という文字列にしてください。列名は `category_id`・`stock_status`・`product_count` とし、`category_id` の昇順、同じ `category_id` の中では `stock_status` の昇順で並べてください。

<details>
<summary>💡 ヒントを見る</summary>

- 「在庫切れ／在庫あり」のように、条件によって表示する文字列を変えたいときは `CASE WHEN 条件 THEN 値1 ELSE 値2 END` を使います。
- `GROUP BY` にはカンマ区切りで複数の列（または `CASE` 式の別名）を指定できます。
- MySQLでは、SELECT句でつけた列の別名（`AS`）を `GROUP BY` や `ORDER BY` で使うことができます。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    category_id,
    CASE WHEN stock_quantity = 0 THEN '在庫切れ' ELSE '在庫あり' END AS stock_status,
    COUNT(*) AS product_count
FROM products
GROUP BY category_id, stock_status
ORDER BY category_id, stock_status;
```

**実行結果イメージ**:

```text
category_id | stock_status | product_count
-------------+--------------+----------------
           1 | 在庫あり     |              4
           2 | 在庫あり     |              3
           3 | 在庫あり     |              3
           4 | 在庫あり     |              3
           4 | 在庫切れ     |              1
           5 | 在庫あり     |              2
```

**解説**:
`GROUP BY category_id, stock_status` のように列を2つ指定すると、「`category_id` と `stock_status` の組み合わせが同じ行」だけが1つのグループになります。日用品カテゴリ（category_id=4）には商品が4件ありますが、そのうち「折りたたみ傘」（product_id=13）だけが在庫数0のため「在庫切れ」グループに分かれ、残りの3件が「在庫あり」グループになります。このように `CASE式` で作った文字列も、集計関数と同じようにグループ分けの基準として使える点がポイントです。

**覚え方のポイント**:
`GROUP BY` に列を増やすほど、グループはより細かく分かれていきます。「カテゴリごと」だけでなく「カテゴリ×在庫状況ごと」のように条件を掛け合わせて分析したいときに複数列の `GROUP BY` が役立つと覚えておきましょう。

</details>

---

## 問題 6: 集計前にデータを絞り込む — WHEREとGROUP BYの実行順序

**目的**: `WHERE` と `GROUP BY` がSQL内でどの順番で処理されるかを理解する

**問題文**:
`employees`（社員）テーブルから、2018年1月1日以降に入社した社員（`hire_date`）だけを対象に、部署ID（`department_id`）ごとの人数を求めてください。列名は `department_id` と `employee_count` にし、`department_id` の昇順で並べてください。

<details>
<summary>💡 ヒントを見る</summary>

- 「集計する前の、1行ずつのデータ」を絞り込みたいので `WHERE` を使います。
- 日付の比較には `hire_date >= '2018-01-01'` のように文字列形式の日付を使えます。
- SQL文の中では `WHERE` は `GROUP BY` より前に書きますが、これは処理される順番とも一致しています。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    department_id,
    COUNT(*) AS employee_count
FROM employees
WHERE hire_date >= '2018-01-01'
GROUP BY department_id
ORDER BY department_id;
```

**実行結果イメージ**:

```text
department_id | employee_count
---------------+-----------------
             1 |               2
             2 |               2
             3 |               1
             4 |               2
```

**解説**:
MySQLはこのSELECT文を、書いてある順番どおりではなく「`FROM` → `WHERE` → `GROUP BY` → `HAVING` → `SELECT` → `ORDER BY`」という順番で処理します。つまり、まず `WHERE hire_date >= '2018-01-01'` によって2018年より前に入社した社員（山田・佐藤・鈴木・高橋・渡辺の5人）が先に除外され、残った7人の社員（田中・伊藤・中村・小林・加藤・吉田・山本）だけを対象に `GROUP BY department_id` で部署ごとの集計が行われます。もし `WHERE` がなければ12人全員が対象になり、問題3の結果と同じになってしまいます。「絞り込みたいのが集計前の生データなのか、集計後の結果なのか」を意識することが、`WHERE` と `HAVING` を正しく使い分けるコツにもつながります。

**覚え方のポイント**:
「まず必要な行だけを選んでから（`WHERE`）、そのあとでグループ分けして計算する（`GROUP BY`）」という2段階の流れをイメージしましょう。実務でも「特定の期間・条件のデータだけを集計したい」という場面は非常に多いため、この組み合わせはよく使います。

</details>

---

## 問題 7: 計算した値を集計する — quantity × unit_price の合計

**目的**: 列同士を計算した結果を集計する方法を理解し、売上金額のような実務指標を求められるようになる

**問題文**:
`order_items`（注文明細）テーブルから、商品ID（`product_id`）ごとに、注文された数量の合計（`total_quantity`）と、売上金額の合計（`total_sales`、数量×単価の合計）を求めてください。`product_id` の昇順で並べてください。

<details>
<summary>💡 ヒントを見る</summary>

- 売上金額は「数量（`quantity`）× 単価（`unit_price`）」で1行ごとに計算できます。
- `SUM(quantity * unit_price)` のように、集計関数の中に計算式を書くことができます。
- 数量の合計は `SUM(quantity)` です。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    product_id,
    SUM(quantity) AS total_quantity,
    SUM(quantity * unit_price) AS total_sales
FROM order_items
GROUP BY product_id
ORDER BY product_id;
```

**実行結果イメージ**:

```text
product_id | total_quantity | total_sales
------------+-----------------+-------------
          1 |               3 |      269400
          2 |               3 |       38400
          3 |               1 |        4980
          4 |               1 |       45800
          5 |               5 |        6000
        ... |             ... |         ...
（product_id=16「電卓」は一度も注文されていないため、この結果には登場しません）
```

**解説**:
`quantity * unit_price` は「その1行（1つの注文明細）の売上金額」を表します。`SUM(quantity * unit_price)` と書くと、まず各行で `quantity * unit_price` が計算され、それを `product_id` ごとのグループでまとめて合計します。たとえばノートパソコン（product_id=1）は3回の注文明細（数量1個ずつ）に登場し、単価89,800円 × 3 = 269,400円が売上合計になります。集計関数の中に四則演算を書けることを知っておくと、「合計金額」「平均単価」のような実務でよく使う指標を1つのSQL文で求められるようになります。なお、一度も注文されていない「電卓」（product_id=16）は `order_items` に行が存在しないため、結果には現れません。

**覚え方のポイント**:
「集計関数の中には、列名だけでなく計算式も書ける」と覚えておきましょう。売上金額のように「単価×数量」で求める指標はECサイトの分析で頻出パターンなので、このSQLの形はそのまま実務でも使えます。

</details>

---

## 問題 8: 集計結果を並び替えて上位N件を見る — 集計 + ORDER BY + LIMIT

**目的**: 集計した結果を並び替え、上位だけを取り出す（ランキング形式で見る）方法を理解する

**問題文**:
`order_items`（注文明細）テーブルから、商品ID（`product_id`）ごとの売上金額の合計（`total_sales`、数量×単価の合計）を求め、売上金額が多い順（降順）に並べて、上位5件だけを表示してください。売上金額が同じ場合は `product_id` の昇順で並べてください。

<details>
<summary>💡 ヒントを見る</summary>

- 問題7と同じように `SUM(quantity * unit_price)` で売上金額を計算します。
- 降順に並べるには `ORDER BY 列名 DESC` を使います。
- `ORDER BY` にはカンマ区切りで複数の並び替え条件を指定でき、先に書いたほうが優先されます。
- 上位N件だけを取り出すには `LIMIT N` を末尾につけます。

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    product_id,
    SUM(quantity * unit_price) AS total_sales
FROM order_items
GROUP BY product_id
ORDER BY total_sales DESC, product_id ASC
LIMIT 5;
```

**実行結果イメージ**:

```text
product_id | total_sales
------------+-------------
          1 |      269400
          4 |       45800
          2 |       38400
         15 |        8900
          5 |        6000
```

**解説**:
このSQLは、まず `GROUP BY product_id` で商品ごとに売上金額を集計し、それを `ORDER BY total_sales DESC` で売上金額が大きい順に並べ替えてから、`LIMIT 5` で上位5件だけを残しています。5位のところで「コーヒー豆(500g)」（product_id=5）と「ビジネス小説」（product_id=9）がどちらも売上6,000円で同点になりますが、`ORDER BY` に `product_id ASC` を2つ目の条件として追加しているため、`product_id` が小さいほう（コーヒー豆)が優先されて5位に入り、結果が毎回同じ順序になるようにしています。同点があるときに並び順を指定しないと、実行するたびに順番が変わってしまう可能性がある点に注意しましょう。

**覚え方のポイント**:
「集計してから並び替えて、必要な件数だけ取り出す」という流れは、売上ランキングや在庫ランキングなど実務のレポート作成で非常によく使うパターンです。同点が発生しそうな集計では、`ORDER BY` に2つ目の並び替え条件（多くの場合はIDなど一意な列）を添えておくと、結果が安定して再現性が高くなることも覚えておきましょう。

</details>

---

## この章のまとめ

- `COUNT`・`SUM`・`AVG`・`MAX`・`MIN` の集計関数を使うと、表全体やグループごとの傾向を一瞬で把握できます。
- `COUNT(*)` は行数そのもの、`COUNT(列)` はNULLを除いた件数という違いを理解しておくと、データの欠損を見つけるのにも役立ちます。
- `GROUP BY` は「同じ値を持つ行をグループにまとめてから集計する」ための構文で、複数列を指定すればより細かい単位で集計できます。
- `WHERE`（集計前の絞り込み）と `HAVING`（集計後の絞り込み）は役割が違うため、条件の中に集計関数が出てくるかどうかで使い分けます。
- `quantity * unit_price` のように計算した値を集計関数の中に書けば、売上金額のような実務指標をそのままSQLで求められます。
- 集計結果に `ORDER BY` と `LIMIT` を組み合わせると、「売上上位5商品」のようなランキング集計ができます。

次のレベルでは、`employees`・`departments`・`orders`・`customers` など複数のテーブルを `JOIN` でつなぎ合わせて、より実務に近いデータの取得方法を学んでいきます。
