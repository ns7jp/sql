# レベル5: データ操作とトランザクション

> 🎯 このレベルで身につくこと
> - INSERT文を使って、新しいデータを1件、または複数件まとめてテーブルに追加できる
> - UPDATE文でデータを安全に更新し、WHERE句を書き忘れる危険性を理解する
> - サブクエリと組み合わせた「条件に合う行だけ」のUPDATE/DELETEが書ける
> - DELETEとTRUNCATEの違いを理解し、データを安全に削除できる
> - トランザクション(BEGIN〜COMMIT/ROLLBACK)を使って、複数の変更をひとまとまりの安全な処理として実行できる

## 使用するテーブル
このレベルでは、customers(顧客)・products(商品)・employees(社員)・orders(注文)・order_items(注文明細)の各テーブルを使います。
これまでのレベルで学んだSELECT(データを「読む」)とは違い、このレベルではINSERT・UPDATE・DELETE(データを「変える」)を扱うため、操作を間違えるとデータそのものが変わってしまう点に注意しながら進めてください。
詳しいER図は [docs/01_schema.md](../docs/01_schema.md) を参照してください。

---

## 問題 1: INSERT基本 — 新しい顧客を1件追加する

**目的**: INSERT文の基本形を使って、テーブルに新しい1件のデータを追加する方法を身につける

**問題文**:
顧客テーブル(customers)に、新しい顧客を1件登録してください。顧客名(customer_name)は「中島 健二」、都道府県(prefecture)は「埼玉県」、メールアドレス(email)は「nakajima@example.com」、会員登録日(registered_date)は「2026-09-01」とします。顧客ID(customer_id)は自動採番(AUTO_INCREMENT)に任せるため、指定しないでください。

<details>
<summary>💡 ヒントを見る</summary>

- INSERT文の基本形は `INSERT INTO テーブル名 (列1, 列2, ...) VALUES (値1, 値2, ...);` です
- customer_idはAUTO_INCREMENTが設定されているため、INSERT文の列リストに含めなければ自動で採番されます
- 文字列(名前・都道府県・メールアドレス)や日付はシングルクォート `'...'` で囲みます
- 列の順番と値の順番は必ず対応させる必要があります

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
INSERT INTO customers (customer_name, prefecture, email, registered_date)
VALUES ('中島 健二', '埼玉県', 'nakajima@example.com', '2026-09-01');
```

**実行結果イメージ**:

```text
Query OK, 1 row affected

-- 追加後、customersテーブルを確認すると以下の行が増えている
customer_id | customer_name | prefecture | email                 | registered_date
------------+---------------+------------+-----------------------+-----------------
13          | 中島 健二      | 埼玉県      | nakajima@example.com  | 2026-09-01
```

**解説**:
INSERT文は「INTO テーブル名」の後ろに追加したい列名を並べ、「VALUES」の後ろにその列に対応する値を同じ順番で並べます。今回はcustomer_idを列リストに含めていないため、AUTO_INCREMENTの仕組みによってMySQLが自動的に次の番号(現在のシードデータでは最大がcustomer_id=12のため、13番)を割り当ててくれます。文字列型(VARCHAR)や日付型(DATE)の値はシングルクォートで囲む必要があり、これを忘れると数値やSQLの一部と誤認識されてエラーになります。列名と値の対応がずれると、例えば都道府県の欄にメールアドレスが入ってしまうといったミスにつながるため、列が多いテーブルほど列名を明示的に書く習慣が大切です。

**覚え方のポイント**:
「列名リストと値リストは、同じ順番の対応表」と覚えましょう。AUTO_INCREMENTの列(主キー)は基本的に自分で指定せず、データベースに任せるのがマナーです。列名を省略して `INSERT INTO customers VALUES (...)` と書くこともできますが、テーブルの列構成が変わったときにバグの原因になりやすいため、実務では列名を省略しない書き方が推奨されます。

</details>

---

## 問題 2: 複数行のINSERT — VALUESを複数指定して一度に追加する

**目的**: 1つのINSERT文で複数行のデータをまとめて追加する方法を身につける

**問題文**:
商品テーブル(products)に、新しい商品を2件まとめて登録してください。1件目は商品名(product_name)「空気清浄機」、カテゴリID(category_id)1(家電)、価格(price)24800円、在庫数(stock_quantity)10個です。2件目は商品名「紅茶ティーバッグ」、カテゴリID2(食品)、価格780円、在庫数120個です。商品ID(product_id)は自動採番に任せてください。

<details>
<summary>💡 ヒントを見る</summary>

- VALUESの後ろに `(値1, 値2, ...), (値1, 値2, ...)` のようにカンマ区切りで複数の組を書くと、1回のINSERT文で複数行を追加できます
- 1つのINSERT文にまとめることで、1行ずつ実行するより効率的にデータを追加できます
- 各行の値の並び順は、最初に書いた列リストの順番と揃える必要があります
- 何行追加されたかは、実行結果の「◯ rows affected」で確認できます

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
INSERT INTO products (product_name, category_id, price, stock_quantity)
VALUES
    ('空気清浄機', 1, 24800, 10),
    ('紅茶ティーバッグ', 2, 780, 120);
```

**実行結果イメージ**:

```text
Query OK, 2 rows affected

-- 追加後、productsテーブルを確認すると以下の2行が増えている
product_id | product_name       | category_id | price | stock_quantity
-----------+--------------------+-------------+-------+-----------------
17         | 空気清浄機          | 1           | 24800 | 10
18         | 紅茶ティーバッグ     | 2           | 780   | 120
```

**解説**:
問題1のINSERT文と違うのは、VALUESの後ろに `(値の組), (値の組)` のようにカンマで区切って複数の行を並べている点だけです。1行ずつ `INSERT INTO ... VALUES (...)` を2回実行しても最終的な結果は同じですが、複数行をまとめて書くことで、データベースへの通信回数が減り、実行速度が速くなります(特にたくさんの行を一度に登録するときに効果を発揮します)。それぞれの行のカッコの中の値の順番は、必ず1行目で指定した列名リスト(product_name, category_id, price, stock_quantity)の順番と一致させる必要があり、順番を間違えると価格の欄に在庫数が入ってしまうといった事故につながります。AUTO_INCREMENTの商品IDは、シードデータの最大値(16)に続けて17、18と自動的に割り当てられます。

**覚え方のポイント**:
「VALUESの後ろのカッコは1行分、カンマでつなげば何行でも追加できる」とイメージしましょう。実務では、CSVファイルなどから何百行ものデータを取り込む際にこの書き方がよく使われます。行数が非常に多い場合は、あまりに巨大な1つのINSERT文にすると失敗したときに原因を特定しづらくなるため、数百〜数千行程度に分割して実行することもあります。

</details>

---

## 問題 3: UPDATE基本 — 在庫数を更新する

**目的**: UPDATE文で既存のデータを書き換える方法と、WHERE句を書き忘れる危険性を理解する

**問題文**:
商品テーブル(products)で、「コーヒー豆(500g)」(product_id=5)の商品が入荷したため、在庫数(stock_quantity)を現在の数量から20個増やしてください。

<details>
<summary>💡 ヒントを見る</summary>

- UPDATE文の基本形は `UPDATE テーブル名 SET 列名 = 新しい値 WHERE 条件;` です
- 「現在の値に20を足す」場合は、`stock_quantity = stock_quantity + 20` のように、右辺に自分自身の列を使って計算できます
- WHERE句を書かないと、テーブルの全ての行が更新されてしまうので注意してください
- 更新対象を1件に絞るには、主キーであるproduct_idで条件を指定するのが確実です

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
UPDATE products
SET stock_quantity = stock_quantity + 20
WHERE product_id = 5;
```

**実行結果イメージ**:

```text
Query OK, 1 row affected

-- 更新後の該当行
product_id | product_name     | category_id | price | stock_quantity
-----------+-------------------+-------------+-------+-----------------
5          | コーヒー豆(500g)  | 2           | 1200  | 120  ← 更新前は100
```

**解説**:
UPDATE文は「SET 列名 = 新しい値」で書き換える内容を指定し、「WHERE 条件」でどの行を対象にするかを絞り込みます。今回は `stock_quantity = stock_quantity + 20` のように、右辺で現在の在庫数(更新前の100)を参照しながら20を足しているため、「今の値をもとに計算した新しい値で上書きする」という動きになります。この問題で最も重要な注意点は、**WHERE句を書き忘れると、productsテーブルの16件全ての商品の在庫数が20ずつ増えてしまう**ということです。UPDATE文はSELECT文と違って画面で確認してから実行するわけではなく、実行した瞬間にデータそのものが書き換わってしまうため、特に業務でUPDATE文を書くときは、先に同じWHERE条件でSELECT文を実行し、「更新したい行だけが正しく絞り込めているか」を確認してからUPDATE文を実行する習慣がとても大切です。

**覚え方のポイント**:
「UPDATEのWHERE忘れは、SELECTのWHERE忘れよりずっと危険」と覚えておきましょう。SELECTでWHEREを忘れても表示される行が増えるだけですが、UPDATEでWHEREを忘れると全行のデータが書き換わってしまいます。実務では、UPDATE文を書いたら実行前に必ずWHERE句があるかを見直す、あるいは先にSELECT文で対象行を確認してからUPDATE文に書き換える、という2段階のチェックを習慣にすると事故を防げます。

</details>

---

## 問題 4: サブクエリを使った条件付きUPDATE

**目的**: サブクエリの結果をWHERE句に使い、「条件に合う複数の行」をまとめて更新する方法を身につける

**問題文**:
商品テーブル(products)のうち、これまでの注文数量の合計(order_itemsのquantityの合計)が5個以上ある、よく売れている商品について、価格(price)を10%値引き(元の価格の90%に)してください。値引き後の価格は小数点以下を四捨五入してください。

<details>
<summary>💡 ヒントを見る</summary>

- 先に「商品ごとの注文数量の合計が5個以上」の商品IDを求めるサブクエリを、order_itemsテーブルに対して`GROUP BY product_id`と`HAVING SUM(quantity) >= 5`で作ります
- そのサブクエリの結果をUPDATE文のWHERE句で`WHERE product_id IN (サブクエリ)`のように使います
- 10%値引き後の価格は `price * 0.9` で計算できます
- 整数に丸めるには `ROUND()` 関数を使います

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
UPDATE products
SET price = ROUND(price * 0.9)
WHERE product_id IN (
    SELECT product_id
    FROM order_items
    GROUP BY product_id
    HAVING SUM(quantity) >= 5
);
```

**実行結果イメージ**:

```text
Query OK, 3 rows affected

-- 更新後の該当商品(価格が10%引きになっている)
product_id | product_name       | price | 備考
-----------+---------------------+-------+-------------------
5          | コーヒー豆(500g)    | 1080  | 更新前1200(注文数量合計5個)
6          | 緑茶ティーバッグ     | 612   | 更新前680(注文数量合計7個)
7          | オリーブオイル       | 882   | 更新前980(注文数量合計6個)
```

**解説**:
このUPDATE文のWHERE句には、`IN (サブクエリ)`という形でSELECT文がまるごと入っています。内側のサブクエリは、order_itemsテーブルを商品ごとにグループ化(`GROUP BY product_id`)し、各商品の注文数量の合計を求めたうえで、`HAVING SUM(quantity) >= 5`によって「合計5個以上売れた商品」だけのproduct_idの一覧に絞り込みます。実際のデータでは、コーヒー豆(500g)(5個)・緑茶ティーバッグ(7個)・オリーブオイル(6個)の3商品が条件に該当し、外側のUPDATE文はこの3商品だけを対象に`price = ROUND(price * 0.9)`を適用します。WHEREの条件を集計結果(サブクエリ)にすることで、「1回の注文数量」ではなく「これまでの累計販売数量」という、元のproductsテーブル単体では持っていない情報をもとに更新対象を選べる点が、この問題のポイントです。

**覚え方のポイント**:
「WHERE句の中に集計サブクエリを入れると、集計結果に基づいてUPDATE/DELETEの対象を絞り込める」というパターンとして覚えましょう。SELECT文でサブクエリを使う練習(レベル4)がそのままUPDATE文やDELETE文のWHERE句にも応用できることを実感できる問題です。実務では「よく売れている商品を値引きする」「一定期間注文がない顧客をキャンペーン対象にする」など、集計結果に基づく一括更新は非常によく使われます。

</details>

---

## 問題 5: DELETE基本 — WHEREの重要性とTRUNCATEとの違い

**目的**: DELETE文でデータを安全に削除する方法と、DELETEとTRUNCATEの違いを理解する

**問題文**:
顧客テーブル(customers)から、これまで一度も注文をしたことがない顧客のうち、customer_id=12(遠藤 舞)を削除してください。

<details>
<summary>💡 ヒントを見る</summary>

- DELETE文の基本形は `DELETE FROM テーブル名 WHERE 条件;` です
- SELECTと同様にWHERE句で削除対象を絞り込みますが、UPDATEと同じく**WHERE句を忘れると全件削除**されてしまいます
- 削除する前に、同じWHERE条件でSELECT文を実行し、対象が正しいか確認する習慣をつけましょう
- 他のテーブル(ordersなど)から外部キーで参照されている行は、参照が残っていると削除時にエラーになります

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
DELETE FROM customers
WHERE customer_id = 12;
```

**実行結果イメージ**:

```text
Query OK, 1 row affected

-- 削除後、customersテーブルにcustomer_id=12の行は存在しない
-- (SELECT * FROM customers WHERE customer_id = 12; → 0件)
```

**解説**:
DELETE文は`DELETE FROM テーブル名 WHERE 条件`という形で、条件に合う行を削除します。今回削除したcustomer_id=12(遠藤 舞)は、シードデータのコメントにある通り「一度も注文していない顧客」の1人であり、ordersテーブルから参照されていないため、外部キー制約に引っかからずに安全に削除できます。反対に、もし注文実績のある顧客(customer_id=1〜10のいずれか)を削除しようとすると、ordersテーブルのcustomer_id列がその顧客を参照しているため、外部キー制約違反のエラーになります。**UPDATE文と同様に、DELETE文もWHERE句を書き忘れると、customersテーブルの全12件が削除されてしまう**という重大な事故につながるため、実行前に必ずWHERE句の内容を見直す習慣が必要です。

**覚え方のポイント**:
DELETEとTRUNCATE(この問題では実行しません)はどちらも「行を削除する」点は同じですが、性質が大きく異なります。DELETEはWHERE句で対象を選べて、トランザクション内であればROLLBACKで取り消せる、1行ずつ処理されるためAUTO_INCREMENTの値もリセットされない、という「安全だが低速」な削除方法です。一方TRUNCATEはWHERE句が使えず必ずテーブルの全件を削除し、実行すると同時に自動的にコミットされてしまうためROLLBACKで取り消せず、AUTO_INCREMENTの値も1にリセットされる「高速だが後戻りできない」削除方法です。「一部の行だけ、安全に消したいならDELETE」「テーブルを完全に空にしてリセットしたいならTRUNCATE」と使い分けを覚えておきましょう。

</details>

---

## 問題 6: トランザクションの基本 — BEGIN(START TRANSACTION)〜COMMITの一連の流れ

**目的**: 複数のSQL文を1つのまとまり(トランザクション)として実行し、まとめて確定(COMMIT)する流れを身につける

**問題文**:
「中山 陽子」さん(customer_id=1)が電話で「コーヒー豆(500g)」(product_id=5)を2個注文した、という業務を想定します。次の3つの処理を1つのトランザクションとして実行し、全て成功したことを確認してからCOMMITしてください。
1. ordersテーブルに、customer_id=1、employee_idはNULL(担当者未定として一旦NULLとします)、order_dateは「2026-09-01」、statusは「処理中」の新しい注文を1件追加する
2. order_itemsテーブルに、直前に追加した注文に対して、product_id=5、quantity=2、unit_price=1200の明細を1件追加する(注文IDは`LAST_INSERT_ID()`関数で直前のINSERTのIDを参照する)
3. productsテーブルのproduct_id=5の在庫数(stock_quantity)を2個減らす

<details>
<summary>💡 ヒントを見る</summary>

- トランザクションは `START TRANSACTION;`(または`BEGIN;`)で開始し、`COMMIT;`で確定します
- 直前のINSERT文で発行されたAUTO_INCREMENTの値は、`LAST_INSERT_ID()`という関数で取得できます
- `LAST_INSERT_ID()`を次のINSERT文の中でそのまま値として使うことで、「今作ったばかりの注文ID」を明細に紐づけられます
- 複数のSQL文を順番に実行し、最後に1回だけCOMMITする、という流れを1つのSQLブロックとして書きます

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
START TRANSACTION;

INSERT INTO orders (customer_id, employee_id, order_date, status)
VALUES (1, NULL, '2026-09-01', '処理中');

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (LAST_INSERT_ID(), 5, 2, 1200);

UPDATE products
SET stock_quantity = stock_quantity - 2
WHERE product_id = 5;

COMMIT;
```

**実行結果イメージ**:

```text
Query OK, 1 row affected   -- INSERT INTO orders (order_id=19が採番される)
Query OK, 1 row affected   -- INSERT INTO order_items (order_id=19に紐づく明細)
Query OK, 1 row affected   -- UPDATE products (stock_quantityが100→98)
Query OK                    -- COMMIT

-- コミット後、以下のように3つのテーブルが整合した状態で確定している
order_id | customer_id | employee_id | order_date | status
---------+-------------+-------------+------------+--------
19       | 1           | NULL        | 2026-09-01 | 処理中

order_item_id | order_id | product_id | quantity | unit_price
---------------+----------+------------+----------+------------
25             | 19       | 5          | 2        | 1200

product_id | stock_quantity
-----------+-----------------
5          | 98   ← 更新前は100
```

**解説**:
`START TRANSACTION;`を実行すると、その後のSQL文は「まだ確定していない仮の変更」として扱われるようになります。この問題では、注文(orders)を1件追加し、その注文に対応する明細(order_items)を追加し、さらに商品の在庫(products)を減らすという、3つのテーブルにまたがる3つの処理を行っていますが、これらは「1件の注文が成立する」という1つの業務のまとまりです。もし注文だけ登録されて在庫が減らなかったり、逆に在庫だけ減って注文が登録されなかったりすると、データの整合性が崩れてしまいます。トランザクションを使うことで、`COMMIT;`が実行されるまでは全ての変更が仮の状態にとどまり、`COMMIT;`を実行して初めて3つの変更が同時に確定します。また、`LAST_INSERT_ID()`を使うことで、1つ目のINSERT文で自動採番されたorder_id(この例では19)を、2つ目のINSERT文の中で明示的に数値を調べなくてもそのまま利用できる点も、実務でよく使うテクニックです。

**覚え方のポイント**:
「複数のテーブルにまたがる変更で、途中で失敗したら全部なかったことにしたい」と思ったら、トランザクションの出番です。MySQLは通常、1文ごとに自動的にコミットされる「自動コミットモード」で動いていますが、`START TRANSACTION;`を書くとその自動コミットが一時的にオフになり、明示的に`COMMIT;`(確定)か`ROLLBACK;`(取り消し、次の問題7で扱います)を書くまでは変更が確定しない、という違いを押さえておきましょう。

</details>

---

## 問題 7: ROLLBACKの実践 — 誤操作を取り消す一連の流れ

**目的**: トランザクション中に誤りに気づいた場合、ROLLBACKでその変更を丸ごと取り消せることを体験する

**問題文**:
給与改定の作業中に、「田中 三郎」さん(department_id=1、salaryは380,000円)の給与を1万円上げるつもりが、誤って100万円(1000000)上げてしまいました。この誤操作をトランザクションの中で行い、コミットする前に誤りに気づいてROLLBACKで取り消し、給与が元の金額(380,000円)のままであることを確認してください。

<details>
<summary>💡 ヒントを見る</summary>

- まず`START TRANSACTION;`でトランザクションを開始します
- UPDATE文で誤って100万円加算する処理を書きます
- 確定する前に`ROLLBACK;`を実行すると、そのトランザクション内で行った変更は全て取り消され、開始前の状態に戻ります
- 最後にSELECT文で給与を確認し、金額が変わっていないことを確かめます

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
START TRANSACTION;

UPDATE employees
SET salary = salary + 1000000
WHERE employee_name = '田中 三郎';

-- ここで金額を1000000円ではなく10000円上げるつもりだったミスに気づいた
ROLLBACK;

SELECT employee_name, salary
FROM employees
WHERE employee_name = '田中 三郎';
```

**実行結果イメージ**:

```text
Query OK, 1 row affected   -- UPDATE直後は一時的に1380000円になっている(まだ確定前)
Query OK                    -- ROLLBACK

-- ROLLBACK後にSELECTした結果、給与は更新前の金額に戻っている
employee_name | salary
--------------+--------
田中 三郎      | 380000
```

**解説**:
UPDATE文を実行した直後の時点では、田中さんの給与は一時的に1,380,000円に書き換わっています。しかし、この変更はまだ`COMMIT;`されていない「仮の状態」であるため、確定した(他の利用者からも見える)データにはなっていません。ここで`ROLLBACK;`を実行すると、`START TRANSACTION;`以降に行った全ての変更(今回はUPDATE1件)がなかったことになり、給与は元の380,000円に戻ります。最後のSELECT文で確認しているように、誤って100万円も昇給させてしまうという重大なミスも、コミットする前であればROLLBACKで安全に取り消せるのが、トランザクションの最大のメリットです。もしトランザクションを使わずに(自動コミットモードのまま)UPDATE文を実行していた場合、実行した瞬間に変更が確定してしまい、元に戻すには改めて「給与を100万円減らすUPDATE文」を実行するしかなく、ミスに気づくのが遅れるほど復旧が難しくなります。

**覚え方のポイント**:
「COMMITするまでは、まだ取り消せる下書きの状態」とイメージしましょう。特に金額や在庫数など、重要なデータをUPDATE/DELETEする作業では、まずトランザクションを開始し、SELECT文で結果を確認してから、問題なければCOMMIT、おかしければROLLBACKという流れを徹底すると、操作ミスによる事故を大きく減らせます。実務では、大量のデータを一括更新するバッチ処理などで、この「確認してからCOMMIT」の考え方が特に重要になります。

</details>

---

## 問題 8: INSERT ... SELECT — 既存データから新しいデータを作る

**目的**: 別のSELECT文の結果をそのままINSERT文の元データとして使い、既存データをもとに新しい行を作る方法を身につける

**問題文**:
商品テーブル(products)にある「SQL入門書」(product_id=8)の情報をもとに、新しい商品「SQL入門書(改訂版)」を追加してください。カテゴリID(category_id)と価格(price)は「SQL入門書」と同じ値を使い、在庫数(stock_quantity)は15個として登録してください。

<details>
<summary>💡 ヒントを見る</summary>

- `INSERT INTO テーブル名 (列1, 列2, ...) SELECT ...` という形で、VALUESの代わりにSELECT文の結果を挿入できます
- SELECT句に書く値の数と順番は、INSERT文の列リストと一致させる必要があります
- 商品名や在庫数のように固定したい値は、SELECT句の中に文字列や数値としてそのまま書くことができます(テーブルの列でなくても構いません)
- カテゴリIDと価格は、SELECT文でproductsテーブルの「SQL入門書」の行から取得します

</details>

<details>
<summary>✅ 模範解答と解説を見る</summary>

**模範解答**:

```sql
INSERT INTO products (product_name, category_id, price, stock_quantity)
SELECT 'SQL入門書(改訂版)', category_id, price, 15
FROM products
WHERE product_name = 'SQL入門書';
```

**実行結果イメージ**:

```text
Query OK, 1 row affected

-- 追加後、productsテーブルを確認すると以下の行が増えている
product_id | product_name          | category_id | price | stock_quantity
-----------+------------------------+-------------+-------+-----------------
17         | SQL入門書(改訂版)      | 3           | 2800  | 15
```

**解説**:
`INSERT INTO ... SELECT ...`という書き方は、`VALUES`の代わりにSELECT文の結果をそのまま挿入するための構文です。この問題では、SELECT句の1列目に固定の文字列`'SQL入門書(改訂版)'`、2列目と3列目に`WHERE product_name = 'SQL入門書'`で絞り込んだ既存商品(product_id=8)のcategory_id(3、書籍)とprice(2800円)、4列目に固定の数値15を並べています。このようにSELECT句には、テーブルの列だけでなく、固定の文字列や数値を混ぜて書くこともでき、「一部の値は既存データからコピーし、一部の値は新しく指定する」という柔軟なデータ作成が可能になります。もしWHERE句の条件に合う行が2件以上あった場合は、その件数分だけ新しい行が追加されてしまう点にも注意が必要です。

**覚え方のポイント**:
「SELECT文で作った結果セットを、そのままテーブルに書き込むのがINSERT ... SELECT」とイメージしましょう。1件ずつVALUESで値を手入力する代わりに、既存のテーブルから条件に合うデータをまとめてコピーしたり、集計結果を別のテーブルに保存したりする場面で非常によく使われます。実務では、月末に注文データを集計して別の履歴用テーブルに保存する、といった処理でこの構文が活躍します。

</details>

---

## この章のまとめ
- INSERT文でデータを追加する際は、1件だけの追加もVALUESを複数並べての一括追加も可能で、AUTO_INCREMENTの列は基本的に指定しないのが原則です。
- UPDATE文とDELETE文は、WHERE句を書き忘れると対象テーブルの全ての行が更新・削除されてしまう危険な操作であるため、実行前に必ずWHERE句を見直す、あるいは同じ条件でSELECT文を試してから実行する習慣が大切です。
- WHERE句にはサブクエリ(集計結果など)を使うこともでき、「累計注文数量が多い商品」のような条件に基づいた一括更新・削除ができます。
- DELETEはWHERE句で対象を選べてROLLBACKも可能な安全な削除方法、TRUNCATEはWHERE句が使えず即座に確定してしまう高速な全件削除方法、という違いを理解しておきましょう。
- トランザクション(START TRANSACTION〜COMMIT/ROLLBACK)を使うと、複数のテーブルにまたがる変更を1つのまとまりとして扱い、全て成功したときだけ確定(COMMIT)し、誤りに気づいたときは丸ごと取り消す(ROLLBACK)ことができます。

次のレベルでは、これまで学んだSELECT・JOIN・サブクエリ・DML操作を組み合わせながら、インデックスやパフォーマンス、より実務に近い複雑な要件のSQLに挑戦していきます。
