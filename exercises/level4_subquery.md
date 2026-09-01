# レベル4: サブクエリ

> 🎯 このレベルで身につくこと
> - サブクエリ(問い合わせの中に入れる別の問い合わせ)を、WHERE句・SELECT句・FROM句のそれぞれで使い分けられる
> - IN、NOT IN、EXISTS、NOT EXISTSの違いと、NULLが絡んだときの落とし穴を理解する
> - 相関サブクエリ(外側の行を1行ずつ参照するサブクエリ)の仕組みを説明できる
> - 「集計してから絞り込む」という2段階の考え方を身につける
> - 同じ結果をサブクエリとJOINの両方で書けるようになり、状況に応じて使い分けられる

## 使用するテーブル
このレベルでは、社員(employees)・顧客(customers)・注文(orders)・商品(products)の各テーブルを使います。
「平均より高い」「まだ注文していない」「部署内で一番高い」といった、1回の集計や絞り込みだけでは書けない条件を、サブクエリで表現していきます。
詳しいER図は [docs/01_schema.md](../docs/01_schema.md) を参照してください。

---

## 問題 1: WHERE句のサブクエリ — 全社員の平均給与より高い社員を探す

**目的**: WHERE句の中に別のSELECT文(サブクエリ)を書いて、集計値と比較する方法を身につける

**問題文**:
社員テーブル(employees)から、「全社員の平均給与」よりも給与(salary)が高い社員を、社員名(employee_name)・所属部署ID(department_id)・給与(salary)の3列で取得してください。給与が高い順に並べてください。

<details>
<summary>💡 ヒントを見る</summary>

- 平均を求めるには `AVG()` 関数を使います
- 「平均給与」を先に1つの値として求めてから、それをWHERE句の比較対象に使います
- `WHERE salary > (SELECT ... )` のように、`( )` の中にもう1つのSELECT文を書くことができます
- 内側のSELECT文(サブクエリ)は先に実行され、1つの値(スカラ値)になります

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    employee_name,
    department_id,
    salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;
```

**実行結果イメージ**:

```text
employee_name | department_id | salary
--------------+----------------+--------
佐藤 花子      | 2              | 680000
山田 太郎      | 1              | 650000
鈴木 一郎      | 3              | 600000
渡辺 健太      | 2              | 540000
高橋 次郎      | 1              | 520000
加藤 綾        | 4              | 500000
(6件)
```

**解説**:
`( )` の中に書かれた `SELECT AVG(salary) FROM employees` が「サブクエリ」です。このサブクエリは先に実行され、全社員12名の平均給与(約478,333円)という1つの数値になります。その後、外側のクエリは `WHERE salary > 478333.33...` を比較しているのと同じ意味になり、各社員の給与と見比べて条件に合う行だけを残します。このように、サブクエリが1行1列の値(スカラ値)を返す場合は、`=`や`>`のような通常の比較演算子でそのまま使うことができます。もし先に平均を求めて画面にメモしてから2つ目のクエリを書く、という2段階の作業をしていたなら、それを1本のSQL文にまとめられるのがサブクエリの利点です。

**覚え方のポイント**:
「先に()の中を1つの答えにしてから、外側で比較する」という順番で読むとわかりやすいです。`WHERE 列名 比較演算子 (SELECT 集計関数(列) FROM テーブル)` の形はとてもよく使うパターンなので、そのまま覚えてしまいましょう。ただし、サブクエリが2行以上返してしまうと`>`や`=`ではエラーになるので、必ず1行1列になる書き方(集計関数を使うなど)にする必要があります。

</details>

---

## 問題 2: IN を使ったサブクエリ — 注文実績のある顧客だけを一覧表示

**目的**: サブクエリが複数の値を返す場合に使う `IN` の使い方を身につける

**問題文**:
顧客テーブル(customers)から、これまでに1回でも注文(ordersテーブルに記録)をしたことがある顧客を、顧客ID(customer_id)と顧客名(customer_name)の2列で、顧客ID順に取得してください。

<details>
<summary>💡 ヒントを見る</summary>

- ordersテーブルに登場する customer_id の一覧を、まずサブクエリで作ります
- サブクエリが複数行を返す場合は `=` ではなく `IN` を使います
- `WHERE customer_id IN (SELECT customer_id FROM orders)` の形になります
- 同じ顧客が複数回注文していても、IN は「その値がリストに含まれているか」だけを見るので重複は気にしなくて大丈夫です

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    customer_id,
    customer_name
FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders)
ORDER BY customer_id;
```

**実行結果イメージ**:

```text
customer_id | customer_name
------------+---------------
1           | 中山 陽子
2           | 木村 健一
3           | 林 美穂
...
10          | 松本 蓮
(10件、customer_id=11,12は含まれない)
```

**解説**:
内側の `SELECT customer_id FROM orders` は、注文が発生するたびに何度も同じ顧客IDが登場するため、複数行を返します。このように複数行が返るサブクエリは、`=` では「値が1つに決まらない」というエラーになるため使えず、代わりに「リストの中に含まれているか」を判定する `IN` を使います。実際のデータでは18件の注文がありますが、注文した顧客はcustomer_id 1〜10の10名で、11番(斉藤 翔)と12番(遠藤 舞)はまだ一度も注文していないため、結果には含まれません。IN句は内部的に重複した値があっても正しく1顧客1回だけ表示してくれる点も、初心者がつまずきやすいポイントなので覚えておきましょう。

**覚え方のポイント**:
`IN` は「サブクエリの結果リストの中に、この値があるかどうか」を調べる演算子です。`WHERE 列名 = 値` の「値」の部分が、単一の値ではなく「値のリスト」になったバージョンだとイメージすると理解しやすいです。次の問題4-3で扱う「注文していない顧客」を探す `NOT IN` とセットで覚えると、両方の使い方がすっきり整理できます。

</details>

---

## 問題 3: NOT IN / NOT EXISTS で「ないもの」を探す

**目的**: 「〜していない」を探す代表的な2つの書き方(NOT IN・NOT EXISTS)と、それぞれの注意点を理解する

**問題文**:
顧客テーブル(customers)から、一度も注文(ordersテーブルに記録)をしたことがない顧客を、顧客ID(customer_id)と顧客名(customer_name)の2列で、顧客ID順に取得してください。

<details>
<summary>💡 ヒントを見る</summary>

- `NOT EXISTS` は「対応する行が存在しない」ことを確認する構文です。カッコの中には、外側のテーブルの行を参照する条件を書きます(これを相関サブクエリと呼びます)
- `NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id)` のように、外側のテーブルにエイリアス(別名)を付けて、内側から参照します
- `SELECT 1` の「1」は特に意味を持たず、「行が存在するかどうか」だけを確認するための書き方の慣習です
- 似た書き方に `NOT IN` もありますが、サブクエリの結果にNULLが1件でも含まれると、`NOT IN`は意図せず0件になってしまう注意点があります

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    customer_id,
    customer_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
)
ORDER BY customer_id;
```

**実行結果イメージ**:

```text
customer_id | customer_name
------------+---------------
11          | 斉藤 翔
12          | 遠藤 舞
(2件)
```

**解説**:
`NOT EXISTS` の中のサブクエリは、外側のcustomersテーブルの1行ごとに実行される「相関サブクエリ」です。`o.customer_id = c.customer_id` という条件で、「この顧客(c)に対応する注文(o)が1件でもあるか」をチェックし、1件も見つからなければその顧客が結果に残ります。この問題は、レベル3の「LEFT JOIN + `WHERE 列 IS NULL`」で書いた問題(3-4)と全く同じ結果(customer_id=11, 12)を返します。LEFT JOINで結合してから片方がNULLの行を探すやり方も、NOT EXISTSで「存在しない」を直接問い合わせるやり方も、どちらも実務でよく使われる書き方です。なお、今回の`orders.customer_id`はNOT NULL制約があるため`NOT IN`を使っても同じ結果になりますが、もし比較する列にNULLが含まれる可能性がある場合は、`NOT IN`は全件が対象外(0件)という予想外の結果になることがあるため、迷ったら`NOT EXISTS`を使うのが安全です。

**覚え方のポイント**:
「EXISTSは存在チェック専用」「値そのものではなく、行があるかないかだけを見る」と覚えましょう。`NOT EXISTS`は「NULLの罠」がないため、実務では`NOT IN`より安全な選択としてよく好まれます。一方でLEFT JOIN + IS NULLの書き方は「両方のテーブルの列を一緒に表示したいとき」に向いているなど、状況に応じた使い分けを意識すると理解が深まります。

</details>

---

## 問題 4: 相関サブクエリと EXISTS — 部署内で最も給与が高い社員を探す

**目的**: 外側の行を1行ずつ参照する「相関サブクエリ」の仕組みを理解する

**問題文**:
社員テーブル(employees)から、各部署(department_id)の中で最も給与(salary)が高い社員を、社員名(employee_name)・所属部署ID(department_id)・給与(salary)の3列で取得してください。部署ID順に並べてください。

<details>
<summary>💡 ヒントを見る</summary>

- 「自分より給与が高い、同じ部署の社員が1人もいない」社員を探す、という考え方を使います
- テーブルに2つの別名(エイリアス)、例えば `e1` と `e2` を付けて、同じemployeesテーブル同士を比較します
- `NOT EXISTS (SELECT 1 FROM employees e2 WHERE e2.department_id = e1.department_id AND e2.salary > e1.salary)` の形になります
- このサブクエリは外側の行(e1の1行ごと)を参照しながら毎回実行されるため「相関サブクエリ」と呼ばれます

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    e1.employee_name,
    e1.department_id,
    e1.salary
FROM employees e1
WHERE NOT EXISTS (
    SELECT 1
    FROM employees e2
    WHERE e2.department_id = e1.department_id
      AND e2.salary > e1.salary
)
ORDER BY e1.department_id;
```

**実行結果イメージ**:

```text
employee_name | department_id | salary
--------------+----------------+--------
山田 太郎      | 1              | 650000
佐藤 花子      | 2              | 680000
鈴木 一郎      | 3              | 600000
加藤 綾        | 4              | 500000
(4件)
```

**解説**:
このクエリのポイントは、同じemployeesテーブルを`e1`と`e2`という2つの別名で使い分けているところです。`e1`は「外側(今チェックしている1人)」、`e2`は「内側(比較対象となる同じ部署の全員)」を表します。内側のサブクエリは、「e1と同じ部署(`e2.department_id = e1.department_id`)で、かつe1より給与が高い(`e2.salary > e1.salary`)社員」を探し、そのような社員が1人も見つからない(`NOT EXISTS`)場合だけ、e1がその部署の最高給与者として結果に残ります。相関サブクエリは、e1の行が変わるたびに内側のSELECTが毎回実行し直される点が、これまでのサブクエリとの大きな違いです。部署4(マーケティング部)には部長がおらず課長の加藤さんがトップという、シードデータのコメント通りの結果になっている点も確認してみましょう。

**覚え方のポイント**:
「自分より上がいない人=一番」という考え方は、ランキングを求めるときの定番パターンです。GROUP BYとMAX()を使う方法(問題4-7で扱います)でも似た結果を作れますが、こちらは「行全体(社員名など全ての列)」を取得したいときに向いています。`e1`・`e2`のような別名がどちらの意味を表しているか迷ったら、「今数えている1人=e1、比較相手の全員=e2」と声に出して確認すると整理しやすいです。

</details>

---

## 問題 5: SELECT句のスカラサブクエリ — 各社員の給与と所属部署の平均給与との差

**目的**: SELECT句の中にサブクエリを書き、各行ごとに追加の集計値を表示する方法を身につける

**問題文**:
社員テーブル(employees)から、社員名(employee_name)・所属部署ID(department_id)・給与(salary)に加えて、「その社員が所属する部署の平均給与」と「給与と部署平均給与との差」を計算し、合計5列で取得してください。部署ID順、部署内は給与が高い順に並べてください。

<details>
<summary>💡 ヒントを見る</summary>

- SELECT句の中にも `( )` で囲んだサブクエリを書くことができます(スカラサブクエリ)
- 部署平均を求めるサブクエリは、`WHERE department_id = 外側のdepartment_id` のように相関させて書きます
- 同じサブクエリを2回使う場合は、`AS` で列名を付けておくと解説や見直しがしやすくなります
- 平均値を見やすくするために `ROUND()` 関数で四捨五入すると良いでしょう

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    e1.employee_name,
    e1.department_id,
    e1.salary,
    (SELECT ROUND(AVG(e2.salary)) FROM employees e2 WHERE e2.department_id = e1.department_id) AS dept_avg_salary,
    e1.salary - (SELECT ROUND(AVG(e2.salary)) FROM employees e2 WHERE e2.department_id = e1.department_id) AS diff_from_avg
FROM employees e1
ORDER BY e1.department_id, e1.salary DESC;
```

**実行結果イメージ**:

```text
employee_name | department_id | salary | dept_avg_salary | diff_from_avg
--------------+----------------+--------+------------------+---------------
山田 太郎      | 1              | 650000 | 477500           | 172500
高橋 次郎      | 1              | 520000 | 477500           | 42500
田中 三郎      | 1              | 380000 | 477500           | -97500
伊藤 陽子      | 1              | 360000 | 477500           | -117500
佐藤 花子      | 2              | 680000 | 505000           | 175000
...
(12件)
```

**解説**:
SELECT句の中に書いたサブクエリは、行ごとに1つの値(スカラ値)を返す必要があるため、「スカラサブクエリ」と呼ばれます。ここでは`e2.department_id = e1.department_id`という条件で、外側の行(e1)が所属する部署のメンバー(e2)だけを対象にAVGを計算しており、これも問題4-4と同じ「相関サブクエリ」の一種です。SELECT句にサブクエリを書くと、GROUP BYを使わずに「明細行はそのまま出しつつ、集計値も一緒に表示する」ことができるのが大きな利点です。ただし同じサブクエリを複数回(平均を出す部分と、差を計算する部分の2回)書いているため、行数が多いテーブルでは実行速度が遅くなりやすい点は、実務で覚えておくとよい注意点です。

**覚え方のポイント**:
「集計はGROUP BYでまとめて表示、明細を保ったまま集計値も見たいときはSELECT句のスカラサブクエリ」と使い分けを覚えましょう。同じサブクエリを2度書くのは冗長に見えますが、初心者のうちはまず「動くこと」を優先し、慣れてきたらウィンドウ関数(`AVG() OVER (PARTITION BY ...)`)というもっと簡潔な書き方があることも将来学んでみてください。

</details>

---

## 問題 6: FROM句のサブクエリ — 一度集計した結果をさらに絞り込む

**目的**: 「先に集計し、その結果をもう一度絞り込む」という2段階のクエリの組み立て方を身につける

**問題文**:
まず顧客ごとの注文合計金額(注文明細の「数量 × 単価」の合計。order_itemsとordersを結合して顧客ごとに集計)を求め、その中から合計金額が50,000円以上の顧客だけを、顧客名(customer_name)と合計金額(total_amount)の2列で、合計金額が高い順に取得してください。

<details>
<summary>💡 ヒントを見る</summary>

- ordersとorder_itemsを結合し、`SUM(quantity * unit_price)` で顧客ごとの合計金額を求めるSELECT文を、まず単独で組み立ててみましょう
- そのSELECT文全体を `( ) AS 別名` として、FROM句の中に入れると、集計結果をまるで1つのテーブルのように扱えます
- FROM句にサブクエリを書いた場合、必ず `AS 別名` で名前を付ける必要があります(MySQLのルール)
- 外側ではその集計結果に対して、customersテーブルを結合したりWHERE句で絞り込んだりできます

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    c.customer_name,
    ct.total_amount
FROM (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS total_amount
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id
) AS ct
JOIN customers c ON c.customer_id = ct.customer_id
WHERE ct.total_amount >= 50000
ORDER BY ct.total_amount DESC;
```

**実行結果イメージ**:

```text
customer_name | total_amount
--------------+--------------
中山 陽子      | 129200
木村 健一      | 97320
清水 大輔      | 96260
(3件)
```

**解説**:
このクエリは2段階構造になっています。まず内側の `( ) AS ct` の部分で、注文と注文明細を結合し、`GROUP BY o.customer_id` で顧客ごとの合計購入金額を計算します。この時点で、まるで「customer_idとtotal_amountだけを持つ新しいテーブル」ができあがったとイメージしてください。それが `ct` という名前で、外側のFROM句から1つのテーブルのように使えるようになります。もし`WHERE total_amount >= 50000`を集計前のorder_itemsに対して直接書こうとすると、「集計する前の1行ごとの金額」に対する条件になってしまい、正しい合計での絞り込みができません。先に集計を確定させてから、その結果を絞り込むためにFROM句のサブクエリが必要になる、という点がこの問題の一番のポイントです。

**覚え方のポイント**:
「GROUP BYで集計した結果に対して、さらにWHEREのような条件を付けたい」と思ったときは、FROM句のサブクエリ(または後で習うHAVING句)を思い出しましょう。FROM句のサブクエリは必ず別名(AS)が必要というMySQLのルールを忘れると構文エラーになりやすいので、書くときは「( ) の直後に AS 別名」とセットで覚えておくと安全です。

</details>

---

## 問題 7: サブクエリで最大値グループを求める — 各カテゴリの最高額商品を探す

**目的**: 「グループごとの最大値の行」を、サブクエリを使って正しく1行ずつ取得する方法を身につける

**問題文**:
商品テーブル(products)から、各カテゴリ(category_id)の中で最も価格(price)が高い商品を、商品名(product_name)・カテゴリID(category_id)・価格(price)の3列で取得してください。カテゴリID順に並べてください。

<details>
<summary>💡 ヒントを見る</summary>

- 先に「カテゴリごとの最高価格」を`GROUP BY category_id`と`MAX(price)`で求めるサブクエリを作ります
- そのサブクエリは `category_id` と `MAX(price)` の2列の組み合わせを複数行返します
- 外側では `WHERE (category_id, price) IN (サブクエリ)` のように、2つの列の組み合わせをまとめて比較できます(MySQLで使える書き方です)
- 「カテゴリIDが一致していて、かつ価格がそのカテゴリの最高額と一致する行」だけが残ります

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    p.product_name,
    p.category_id,
    p.price
FROM products p
WHERE (p.category_id, p.price) IN (
    SELECT category_id, MAX(price)
    FROM products
    GROUP BY category_id
)
ORDER BY p.category_id;
```

**実行結果イメージ**:

```text
product_name       | category_id | price
--------------------+-------------+-------
ノートパソコン       | 1           | 89800
コーヒー豆(500g)     | 2           | 1200
SQL入門書            | 3           | 2800
折りたたみ傘         | 4           | 1980
レディースバッグ      | 5           | 8900
(5件)
```

**解説**:
単純に`GROUP BY category_id`と`MAX(price)`だけを使うと、「カテゴリごとの最高価格」という数値は分かっても、その価格が「どの商品なのか(商品名)」は分かりません。MAX()と一緒にproduct_nameをSELECT句に書くとエラーになったり、意図しない商品名が表示されたりします。そこでこの問題では、先にサブクエリで「カテゴリごとの最高価格の組み合わせ(category_id, MAX(price))」のリストを作り、外側で商品テーブル全体からその組み合わせに一致する行だけを`(列1, 列2) IN (...)`というタプル(複数列の組)比較で絞り込んでいます。こうすることで、価格だけでなく商品名を含めた行全体を正しく取得できます。

**覚え方のポイント**:
「MAXやMINなど集計値と一緒に、他の列(商品名など)も表示したい」と思ったら、まず集計だけのサブクエリを作り、それを条件にして元のテーブルから該当行を探し直す、という2段構えを思い出しましょう。`(列1, 列2) IN (...)`というタプル比較はMySQLならではの便利な書き方なので、覚えておくとランキングや最大値グループの抽出がぐっと書きやすくなります。

</details>

---

## 問題 8: サブクエリとJOINの使い分けまとめ — 同じ結果を両方の書き方で書いて比較する

**目的**: これまで学んだサブクエリの一部は、JOINを使っても同じ結果を書けることを理解し、使い分けの感覚を身につける

**問題文**:
問題4-2と同じ「注文実績のある顧客」(顧客ID・顧客名)を、今度はサブクエリを使わず、ordersテーブルとのJOINだけを使って取得してください。顧客ID順に並べ、同じ顧客が重複して表示されないようにしてください。

<details>
<summary>💡 ヒントを見る</summary>

- customersとordersを`customer_id`で内部結合(INNER JOIN)すると、注文した回数分だけ同じ顧客が複数回出てきてしまいます
- 重複を1行にまとめるには `DISTINCT` を使います
- 問題4-2の`IN`サブクエリの結果と、件数や中身が一致しているか見比べてみましょう

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答(サブクエリ版・問題4-2の再掲)**:

```sql
SELECT customer_id, customer_name
FROM customers
WHERE customer_id IN (SELECT DISTINCT customer_id FROM orders)
ORDER BY customer_id;
```

**模範解答(JOIN版)**:

```sql
SELECT DISTINCT
    c.customer_id,
    c.customer_name
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id;
```

**実行結果イメージ**:

```text
customer_id | customer_name
------------+---------------
1           | 中山 陽子
2           | 木村 健一
3           | 林 美穂
...
10          | 松本 蓮
(どちらの書き方でも10件、結果は完全に一致する)
```

**解説**:
2つのSQL文は書き方が違うだけで、返ってくる結果(customer_id 1〜10の10名)は完全に同じです。サブクエリ版は「ordersに存在するcustomer_idのリストの中に含まれるか」という考え方で、customersテーブルの列(customer_id, customer_name)だけをそのまま使うため、直感的で読みやすいのが特徴です。一方JOIN版は、customersとordersを実際に結合してから`DISTINCT`で重複を取り除く方法で、もし将来「注文日や注文ステータスも一緒に表示したい」のように、ordersテーブル側の列も結果に含めたくなった場合には、JOINの方が自然に拡張できます。逆に、他のテーブルの列は不要で「存在するかどうか」だけを判定したい場合は、サブクエリ(IN・EXISTS)の方がシンプルで、MySQLの最適化エンジンが効率よく処理してくれることも多くあります。

**覚え方のポイント**:
「他のテーブルの列も一緒に表示したいならJOIN、存在チェックや絞り込みの条件として使うだけならサブクエリ」というのが基本的な判断基準です。最初はどちらか一方の書き方に慣れれば十分ですが、同じ結果を2通りの方法で書けるようになると、複雑なクエリを見たときに「これはJOINでも書き換えられそうだ」といった読み替えができるようになり、SQLへの理解が一段深くなります。

</details>

---

## この章のまとめ
- サブクエリは書く場所によって役割が変わります。WHERE句なら「絞り込みの条件」、SELECT句なら「行ごとの追加の値」、FROM句なら「先に作っておく集計済みテーブル」として使います。
- サブクエリが1行1列を返すときは`=`や`>`などの比較演算子、複数行を返すときは`IN`、「存在するかどうか」だけを見たいときは`EXISTS`/`NOT EXISTS`を使います。
- `NOT IN`はサブクエリの結果にNULLが含まれると意図せず0件になる罠があるため、「〜が存在しない」を調べたいときは`NOT EXISTS`の方が安全です。
- 相関サブクエリ(外側の行を1行ずつ参照するサブクエリ)を使うと、「同じ部署内で一番」のような、グループごとの比較が可能になります。
- 同じ結果でもサブクエリとJOINの両方で書けることが多く、状況に応じて読みやすさや拡張のしやすさで使い分けます。

次のレベルでは、これまで学んだJOINやサブクエリを組み合わせながら、ウィンドウ関数など、より実務に近い集計・分析の書き方を学んでいきます。
