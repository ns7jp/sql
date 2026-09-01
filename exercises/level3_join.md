# レベル3: テーブルの結合（JOIN）

> 🎯 このレベルで身につくこと
> - 複数のテーブルを結合して、欲しいデータをまとめて取得する方法（INNER JOIN）
> - 3つ以上のテーブルをつなげて、必要な情報を1つの表にまとめる方法
> - LEFT JOINを使って「関連するデータが存在しない行」を見つける方法
> - 同じテーブル同士を結合する自己結合（self join）で、上司・部下のような階層構造を扱う方法
> - JOINとGROUP BY・HAVINGを組み合わせて、結合結果を集計・絞り込みする方法

## 使用するテーブル
このレベルでは、社内の組織データを表す `departments`（部署）・`employees`（社員）と、
ECサイトの受注データを表す `customers`（顧客）・`orders`（注文）・`order_items`（注文明細）・
`products`（商品）を組み合わせて使います。テーブル同士を「主キー（PRIMARY KEY）」と
「外部キー（FOREIGN KEY）」でつなぐことで、バラバラに保存されているデータを1つの表として
取り出せるようになります。
詳しいER図は [docs/01_schema.md](../docs/01_schema.md) を参照してください。

---

## 問題 1: 2テーブルの結合の基本 — INNER JOIN、ON句の書き方

**目的**: INNER JOINとON句を使って、2つのテーブルを結合する基本の書き方を身につける

**問題文**:
`employees`（社員）テーブルと`departments`（部署）テーブルを結合して、社員ID・社員名・
所属する部署名・役職の一覧を、社員ID順に表示してください。

なお「INNER JOIN（内部結合）」とは、2つのテーブルのうち、指定した条件（ON句）で
一致するデータがある行だけを取り出す結合方法のことです。

<details>
<summary>💡 ヒントを見る</summary>

- 結合には `FROM テーブルA INNER JOIN テーブルB ON 結合条件` という形を使います
- ON句には、`employees`テーブルの`department_id`列と`departments`テーブルの
  `department_id`列が一致する条件を書きます
- 同じ列名が複数のテーブルにある場合は、`テーブル名.列名`のように書くか、
  `AS`でテーブルに短い別名（エイリアス）をつけて`別名.列名`と書くとすっきりします
- 並び順はいつも通り`ORDER BY`で指定します

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    e.employee_id,
    e.employee_name,
    d.department_name,
    e.position
FROM employees AS e
INNER JOIN departments AS d ON e.department_id = d.department_id
ORDER BY e.employee_id;
```

**実行結果イメージ**:

```text
employee_id | employee_name | department_name | position
------------+---------------+------------------+---------
1           | 山田 太郎      | 営業部            | 部長
2           | 佐藤 花子      | 開発部            | 部長
3           | 鈴木 一郎      | 総務部            | 部長
4           | 高橋 次郎      | 営業部            | 課長
...
（全12件）
```

**解説**:
`FROM employees AS e INNER JOIN departments AS d ON e.department_id = d.department_id`は、
「employeesテーブルの各行について、department_idが一致するdepartmentsテーブルの行をくっつける」
という意味です。ON句に書く条件が、2つのテーブルをつなぐ「のり」の役割を果たします。
`e`や`d`はテーブルの別名（エイリアス）で、`department_id`のようにどちらのテーブルにも
存在する列名を書くときに、`e.department_id`なのか`d.department_id`なのかを区別するために
使います。今回はすべての社員が必ずどこかの部署に所属している（`department_id`がNOT NULL）ので、
INNER JOINでも12人全員が結果に表示されます。

**覚え方のポイント**:
INNER JOINは「両方のテーブルに存在するものだけを残す」と覚えましょう。SELECTで指定する列は
`FROM`句や`JOIN`句で登場させたどのテーブルの列でも自由に選べる、という点も重要です。
テーブルが2つ以上出てくるクエリでは、癖として最初から`AS`でエイリアスをつける習慣をつけると、
後で列が増えたときにも読みやすいSQLになります。

</details>

---

## 問題 2: 3テーブル以上の結合 — JOINを複数回つなげる（顧客・注文・注文明細）

**目的**: JOINを複数回書きつなげて、3つ以上のテーブルからまとめてデータを取得する方法を身につける

**問題文**:
顧客「中山 陽子」が注文した商品明細を一覧表示してください。表示する項目は、注文ID・
注文日・数量・単価とし、注文日の古い順、同じ注文の中では注文明細ID順に並べてください。

`customers`（顧客）・`orders`（注文）・`order_items`（注文明細）の3つのテーブルを
結合して取得します。

<details>
<summary>💡 ヒントを見る</summary>

- `customers`と`orders`は`customer_id`で、`orders`と`order_items`は`order_id`で結合します
- JOINは`A INNER JOIN B ON ... INNER JOIN C ON ...`のように何回でも書き足せます
- 特定の顧客に絞り込むには`WHERE`句で`customer_name = '中山 陽子'`のように指定します
- 並び順は複数指定でき、`ORDER BY 列1, 列2`のようにカンマで区切って書きます

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    o.order_id,
    o.order_date,
    oi.quantity,
    oi.unit_price
FROM customers AS c
INNER JOIN orders AS o ON c.customer_id = o.customer_id
INNER JOIN order_items AS oi ON o.order_id = oi.order_id
WHERE c.customer_name = '中山 陽子'
ORDER BY o.order_date, oi.order_item_id;
```

**実行結果イメージ**:

```text
order_id | order_date | quantity | unit_price
---------+------------+----------+-----------
1        | 2023-01-05 | 1        | 89800
1        | 2023-01-05 | 2        | 500
4        | 2023-01-20 | 1        | 12800
13       | 2023-04-02 | 2        | 12800
（4件）
```

**解説**:
JOINは1文の中に何個でも書き足すことができ、「customersとordersを結合した結果」に対して、
さらに「order_itemsを結合する」というイメージで処理が進みます。今回のように主キー→外部キーを
順番にたどっていけば、テーブルがいくつ増えても書き方は同じです。`WHERE c.customer_name = '中山 陽子'`は
JOINしたあとの結果に対して絞り込みをかけています。なお注文4はステータスが「キャンセル」ですが、
この問題では注文が存在すること自体を確認したいのでステータスによる絞り込みは行っていません。

**覚え方のポイント**:
テーブルを3つ以上つなげるときは、「どの列とどの列が一致するか」を1つずつ図に描き起こしてから
SQLを書くと迷いません。JOINの数は、基本的に「使うテーブルの数 − 1」になります。今回は
テーブルが3つなのでJOINが2回、という関係を覚えておくと文法ミスが減ります。

</details>

---

## 問題 3: LEFT JOINで「存在しない関連」を探す① — 担当者が未設定の注文を探す

**目的**: LEFT JOINと`IS NULL`を組み合わせて、「一致する相手がいない行」を見つける方法を身につける

**問題文**:
担当社員が設定されていない注文（Webサイトから直接注文されたもの）の一覧を、注文ID順に
表示してください。表示する項目は、注文ID・顧客名・注文日・ステータスとします。

「LEFT JOIN（左外部結合）」とは、左側に書いたテーブルの行はすべて残し、右側のテーブルに
一致するデータがなければその部分をNULL（値なし）で埋める結合方法です。

<details>
<summary>💡 ヒントを見る</summary>

- `orders`を左側にして`employees`とLEFT JOINします
- 担当者がいない注文は、結合後に`employees`側の`employee_id`列がNULLになります
- `WHERE`句で`employee_id IS NULL`のように書いて絞り込みます（`= NULL`ではなく`IS NULL`と書く点に注意）
- 顧客名も表示したいので`customers`テーブルも結合します（すべての注文には必ず顧客が紐づくので、こちらはINNER JOINでかまいません）

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    o.order_id,
    c.customer_name,
    o.order_date,
    o.status
FROM orders AS o
INNER JOIN customers AS c ON o.customer_id = c.customer_id
LEFT JOIN employees AS e ON o.employee_id = e.employee_id
WHERE e.employee_id IS NULL
ORDER BY o.order_id;
```

**実行結果イメージ**:

```text
order_id | customer_name | order_date | status
---------+----------------+------------+----------
2        | 木村 健一       | 2023-01-08 | 完了
4        | 中山 陽子       | 2023-01-20 | キャンセル
6        | 森田 由紀       | 2023-02-10 | 発送済み
8        | 石田 健太       | 2023-02-18 | 処理中
10       | 林 美穂         | 2023-03-05 | 完了
...
（9件）
```

**解説**:
`LEFT JOIN employees AS e ON o.employee_id = e.employee_id`と書くと、ordersの行は
employeesに一致する行があってもなくても、すべて結果に残ります。一致しなかった場合、
`e`側の列はすべてNULLになります。そこで`WHERE e.employee_id IS NULL`とすることで、
「employeesに一致する担当者がいなかった注文」だけを絞り込めます。この
「LEFT JOIN＋IS NULL」の組み合わせは、SQLで「関連するデータが存在しない行」を探す
ときの定番パターンです。今回はたまたま`orders.employee_id`自体を見てもわかりますが、
結合先テーブルの主キー（ここでは`e.employee_id`）がNULLかどうかで判定するこの書き方を
覚えておくと、他のテーブルの組み合わせでも同じ考え方が使えます。

**覚え方のポイント**:
このパターンは「アンチ結合（anti join）」とも呼ばれ、「未対応」「未処理」「未登録」といった
実務データを探すときによく使います。判定には、結合先テーブルの主キー（必ず値が入っている列）を
使うのがポイントです。任意の列でIS NULLを見てしまうと、その列がたまたまNULLなだけのケースと
区別できず、誤った結果になることがあります。

</details>

---

## 問題 4: LEFT JOINで「存在しない関連」を探す② — 一度も注文していない顧客を探す

**目的**: LEFT JOINを使って、関連する行が1つも存在しないマスタデータを探す方法を身につける

**問題文**:
一度も注文をしたことがない顧客の一覧を、顧客ID順に表示してください。表示する項目は、
顧客ID・顧客名・メールアドレスとします。

<details>
<summary>💡 ヒントを見る</summary>

- `customers`を左側にして`orders`とLEFT JOINします
- 注文が1件もない顧客は、結合後に`orders`側の列がすべてNULLになります
- `WHERE`句で`orders`の`order_id`列が`IS NULL`の行だけに絞り込みます
- 問題3と同じ考え方を、「注文の担当者」ではなく「顧客そのもの」に当てはめるだけです

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    c.customer_id,
    c.customer_name,
    c.email
FROM customers AS c
LEFT JOIN orders AS o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;
```

**実行結果イメージ**:

```text
customer_id | customer_name | email
------------+----------------+---------------------
11          | 斉藤 翔        | saito@example.com
12          | 遠藤 舞        | endo@example.com
（2件）
```

**解説**:
考え方は問題3とまったく同じです。「customers（すべての顧客）」を左側に置いて
LEFT JOINすることで、注文がある顧客もない顧客もすべて一旦結果に残します。そのうえで、
右側の`orders`テーブルの主キーである`order_id`が`IS NULL`の行だけに絞り込むと、
「1件も注文と一致しなかった顧客」、つまり一度も注文していない顧客だけが残ります。
LEFT JOINでは、どちらのテーブルを左（先に書く方）にするかが重要です。今回は
「全顧客を基準にしたい」ので`customers`を左に置いています。

**覚え方のポイント**:
「AのうちBに存在しないものを探したい」ときは、`A LEFT JOIN B ON ... WHERE B.主キー IS NULL`
という型で覚えておくと応用が効きます。この型は、未購入顧客のほかにも「在庫はあるが一度も
発注されていない商品」など、さまざまな場面で使えます。今後のレベルで学ぶ`NOT EXISTS`や
`NOT IN`でも同じことができますが、JOINベースのこの書き方をまず基本として押さえておきましょう。

</details>

---

## 問題 5: 自己結合（self join） — 社員テーブルを自分自身と結合して上司名を表示

**目的**: 同じテーブルを2回使う自己結合（self join）の考え方を身につける

**問題文**:
全社員について、社員ID・社員名・役職・上司の氏名を一覧表示してください。上司がいない
社員（部長など、`manager_id`がNULLの社員）については、上司名の代わりに
「(上司なし)」と表示してください。並び順は社員ID順とします。

<details>
<summary>💡 ヒントを見る</summary>

- `employees`テーブルを1つの文の中で2回使います。1回目は社員本人、2回目は上司として扱います
- `AS`で別名を2つ用意して区別します（例: `e`＝社員本人、`m`＝上司）
- 結合条件は「社員本人の`manager_id` ＝ 上司の`employee_id`」です
- 上司がいない社員（`manager_id`がNULL）も結果に残したいのでLEFT JOINを使い、
  結果がNULLになる部分は`COALESCE(列, 'デフォルト値')`関数で置き換えます

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    e.employee_id,
    e.employee_name,
    e.position,
    COALESCE(m.employee_name, '(上司なし)') AS manager_name
FROM employees AS e
LEFT JOIN employees AS m ON e.manager_id = m.employee_id
ORDER BY e.employee_id;
```

**実行結果イメージ**:

```text
employee_id | employee_name | position | manager_name
------------+---------------+----------+---------------
1           | 山田 太郎      | 部長      | (上司なし)
2           | 佐藤 花子      | 部長      | (上司なし)
3           | 鈴木 一郎      | 部長      | (上司なし)
4           | 高橋 次郎      | 課長      | 山田 太郎
5           | 田中 三郎      | 一般      | 高橋 次郎
...
（全12件）
```

**解説**:
自己結合とは、1つのテーブルを鏡合わせのように2回登場させて結合するテクニックです。
`employees AS e`を「社員本人」、`employees AS m`を「上司」という別の役割として扱い、
`e.manager_id = m.employee_id`という条件でつなげることで、「自分の上司が誰か」を
1行にまとめて表示できます。同じテーブルなので、必ず異なるエイリアスをつけないと
どちらの`employee_name`を指しているのか区別できずエラーになります。ここでINNER JOINを
使うと、`manager_id`がNULLの4名（山田・佐藤・鈴木・加藤）は上司側に一致する行がなく
結果から消えてしまうため、あえてLEFT JOINを使い、`COALESCE`関数でNULLを
「(上司なし)」という分かりやすい文字列に置き換えています。

**覚え方のポイント**:
自己結合は「同じ表を2枚コピーして、片方を"自分"役、もう片方を"相手"役にする」とイメージすると
理解しやすいです。上司・部下だけでなく、カテゴリの親子関係など「同じ種類のデータ同士が
親子関係を持つ」場面で幅広く使われます。トップ層（上司なし）を消さずに残したいときは
LEFT JOIN＋COALESCEを組み合わせる、という点はよく忘れがちなので注意しましょう。

</details>

---

## 問題 6: 結合した上で集計する — 社員ごとの売上合計（JOIN + GROUP BY）

**目的**: JOINとGROUP BYを組み合わせて、複数テーブルにまたがる集計を行う方法を身につける

**問題文**:
注文対応をしたことがある社員について、社員ごとの売上合計金額（数量×単価の合計）を、
金額の大きい順に表示してください。表示する項目は、社員名・売上合計金額とします。
担当者が設定されていない注文（Web直接注文）は集計対象に含めません。

<details>
<summary>💡 ヒントを見る</summary>

- `employees`・`orders`・`order_items`の3つのテーブルを結合します
- 1件の明細の金額は「数量 × 単価」で計算し、`SUM`関数で合計します
- `GROUP BY`には集計の単位となる列（社員のIDなど）を指定します
- 金額の大きい順に並べるには`ORDER BY 合計金額 DESC`のように書きます

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    e.employee_name,
    SUM(oi.quantity * oi.unit_price) AS total_sales
FROM employees AS e
INNER JOIN orders AS o ON e.employee_id = o.employee_id
INNER JOIN order_items AS oi ON o.order_id = oi.order_id
GROUP BY e.employee_id, e.employee_name
ORDER BY total_sales DESC;
```

**実行結果イメージ**:

```text
employee_name | total_sales
--------------+------------
伊藤 陽子      | 140400
高橋 次郎      | 115400
田中 三郎      | 109580
（3件）
```

**解説**:
`employees`と`orders`をINNER JOINでつなぐと、`orders.employee_id`がNULLの注文
（Web直接注文）は`employees`側に一致する行がないため、自動的に集計対象から外れます。
これがヒントにあった「担当者が設定されていない注文は含めない」を実現している部分です。
さらに`order_items`をJOINすることで、注文明細1行ごとの金額（`quantity * unit_price`）を
計算できるようになり、それを`SUM`で社員ごとに合計しています。`GROUP BY`には
`employee_id`と`employee_name`の両方を指定していますが、これは「同じ社員IDなら
社員名も1つに決まる」という関係を明示するためで、MySQLでは慣習的にこう書きます。

**覚え方のポイント**:
JOINしてから集計する場合、まず「集計する前の1行が何を表しているか」を意識しましょう。
今回は「注文明細1行＝商品1種類の注文」が集計前の単位です。なお、この結果には
ステータスが「キャンセル」の注文の金額も含まれています。実務では
`WHERE o.status <> 'キャンセル'`のように、集計前にステータスで絞り込むことも
よくあるので、余裕があれば試してみてください。

</details>

---

## 問題 7: 結合+集計+HAVING — 一定額以上を売り上げた社員だけを抽出

**目的**: `HAVING`句を使って、集計した「後」の結果に条件をつける方法を身につける

**問題文**:
問題6と同じ売上集計のうち、売上合計金額が110,000円以上の社員だけを、金額の大きい順に
表示してください。表示する項目は、社員名・売上合計金額とします。

<details>
<summary>💡 ヒントを見る</summary>

- `WHERE`は集計「前」の1行1行に対する条件、`HAVING`は集計「後」の合計値に対する条件です
- `SUM(...)`で計算した合計に対して条件をつけるときは`HAVING`を使います
- `HAVING`は`GROUP BY`の後、`ORDER BY`の前に書きます
- `SUM`の式（数量×単価の合計）は`SELECT`句と`HAVING`句の両方に書く必要があります

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    e.employee_name,
    SUM(oi.quantity * oi.unit_price) AS total_sales
FROM employees AS e
INNER JOIN orders AS o ON e.employee_id = o.employee_id
INNER JOIN order_items AS oi ON o.order_id = oi.order_id
GROUP BY e.employee_id, e.employee_name
HAVING SUM(oi.quantity * oi.unit_price) >= 110000
ORDER BY total_sales DESC;
```

**実行結果イメージ**:

```text
employee_name | total_sales
--------------+------------
伊藤 陽子      | 140400
高橋 次郎      | 115400
（2件）
```

**解説**:
問題6の結果は3名でしたが、`HAVING SUM(oi.quantity * oi.unit_price) >= 110000`を
加えることで、合計金額が109,580円だった田中三郎さんが結果から外れ、2名だけになります。
`WHERE`は「まだ集計していない、生の行」に対する条件なので、`WHERE`の段階では`SUM`の
結果はまだ存在せず、`WHERE SUM(...) >= 110000`のようには書けません（エラーになります）。
SQLの実行はおおまかに「`FROM`・`JOIN`で表をつなぐ→`WHERE`で行を絞る→`GROUP BY`で
まとめる→`HAVING`でまとめた結果を絞る→`ORDER BY`で並べる」という順番で考えると
整理しやすいです。

**覚え方のポイント**:
「`WHERE`は個々の行、`HAVING`はまとめた後の集計値」と覚えましょう。売上・件数などの
「一定基準を超えたものだけを抽出する」というのは、レポート作成などの実務で非常によく
使われるパターンです。`WHERE`と`HAVING`を混同してエラーになるのは初心者が最もつまずき
やすいポイントの1つなので、意識して区別する練習をしておくと後々楽になります。

</details>

---

## 問題 8: 総合問題 — 複数のJOINを組み合わせて読みやすい注文一覧を作る

**目的**: これまで学んだINNER JOINとLEFT JOINを複数組み合わせて、実務で使うような読みやすい一覧を作る

**問題文**:
注文明細を、以下の項目を持つ読みやすい一覧として表示してください。並び順は注文ID順、
同じ注文の中では注文明細ID順とします。

- 注文ID
- 顧客名
- 担当者名（担当者が設定されていない場合は「Web直接注文」と表示する）
- 注文日
- ステータス
- 商品名
- 数量
- 単価
- 小計（数量×単価）

<details>
<summary>💡 ヒントを見る</summary>

- `customers`・`order_items`・`products`はすべての注文に必ず紐づくのでINNER JOINでよい
- `employees`だけは担当者が設定されていない場合があるのでLEFT JOINを使う
- 担当者名がNULLのときの表示には`COALESCE`関数を使う
- 小計はGROUP BYで集計するのではなく、明細1行ごとに「数量×単価」を計算するだけでよい

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
SELECT
    o.order_id,
    c.customer_name,
    COALESCE(e.employee_name, 'Web直接注文') AS staff_name,
    o.order_date,
    o.status,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS subtotal
FROM orders AS o
INNER JOIN customers AS c ON o.customer_id = c.customer_id
LEFT JOIN employees AS e ON o.employee_id = e.employee_id
INNER JOIN order_items AS oi ON o.order_id = oi.order_id
INNER JOIN products AS p ON oi.product_id = p.product_id
ORDER BY o.order_id, oi.order_item_id;
```

**実行結果イメージ**:

```text
order_id | customer_name | staff_name | order_date | status | product_name          | quantity | unit_price | subtotal
---------+----------------+------------+------------+--------+------------------------+----------+------------+---------
1        | 中山 陽子       | 田中 三郎   | 2023-01-05 | 完了    | ノートパソコン           | 1        | 89800      | 89800
1        | 中山 陽子       | 田中 三郎   | 2023-01-05 | 完了    | ボールペン(10本セット)   | 2        | 500        | 1000
2        | 木村 健一       | Web直接注文 | 2023-01-08 | 完了    | コーヒー豆(500g)        | 3        | 1200       | 3600
...
（全24件）
```

**解説**:
この問題では、必ずデータが存在する関係（顧客・注文明細・商品）にはINNER JOINを、
存在しないこともある関係（注文に対する担当社員）にはLEFT JOINを使い分けています。
1つのクエリの中でINNER JOINとLEFT JOINを混ぜて使っても問題ありません。ポイントは、
LEFT JOINした`employees`より後に書いた`order_items`や`products`とのJOINは、
`employees`とは無関係に（`orders`や`order_items`を基準に）結合されるため、
問題なく全件が残るという点です。`COALESCE(e.employee_name, 'Web直接注文')`のように、
NULLをそのまま見せるのではなく意味のある文字列に置き換えることで、業務担当者が見ても
理解しやすい一覧表になります。

**覚え方のポイント**:
テーブルが増えてJOINが複雑になってきたら、書く前に「このテーブルには必ず対応する行が
あるか（INNER JOINでよい）、ないこともあるか（LEFT JOINが必要）」を1つずつ整理する
習慣をつけましょう。列名にも`staff_name`や`subtotal`のようにわかりやすい別名（AS）を
つけておくと、そのままレポートや画面表示に使えるような結果になります。

</details>

---

## この章のまとめ
- INNER JOINは、ON句で指定した条件が両方のテーブルで一致する行だけを取り出す結合方法です
- JOINは複数回つなげることができ、3つ以上のテーブルからまとめてデータを取得できます
- LEFT JOINは左側のテーブルの行をすべて残し、一致しない部分をNULLで埋める結合方法です。`IS NULL`と組み合わせることで「関連するデータが存在しない行」を見つけられます
- 自己結合（self join）は、同じテーブルを別名で2回使うことで、社員と上司のような階層構造を1つの表として扱えます
- JOINした結果にGROUP BYを組み合わせると複数テーブルにまたがる集計ができ、HAVINGを使うと集計した後の値そのものに条件をつけられます（WHEREは集計前、HAVINGは集計後、という違いに注意しましょう）

次のレベル4では、サブクエリ（副問い合わせ）を使って、JOINだけでは書きにくい、さらに複雑な条件でデータを絞り込む方法を学びます。
