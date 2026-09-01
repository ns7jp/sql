-- =====================================================================
-- SQL基礎演習案件パック - テーブル定義（スキーマ）
--
-- テーマ：架空のネットショップ運営会社「サンプル商事」の社内データベース
--   ・部署/社員      … 社内の組織データ（自己結合の練習用に上司IDを持つ）
--   ・カテゴリ/商品   … 販売する商品データ
--   ・顧客/注文/注文明細 … ECサイトの受注データ
--
-- 対応DB：MySQL 8.0 系（docker/docker-compose.yml と組み合わせて利用）
-- 文字コード：utf8mb4（絵文字や機種依存文字も扱えるように統一）
-- =====================================================================

-- 学習中に何度もやり直せるよう、既存テーブルを一度削除してから作り直す。
-- 外部キーの参照順があるため、削除は「参照される側」を後回しにする。
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

-- ---------------------------------------------------------------------
-- departments（部署）
-- ---------------------------------------------------------------------
CREATE TABLE departments (
    department_id   INT             NOT NULL AUTO_INCREMENT COMMENT '部署ID（主キー）',
    department_name VARCHAR(50)     NOT NULL COMMENT '部署名',
    location        VARCHAR(50)     NOT NULL COMMENT '所在地（勤務地）',
    PRIMARY KEY (department_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='部署マスタ';

-- ---------------------------------------------------------------------
-- employees（社員）
--   manager_id は「自分の上司の社員ID」を指す自己参照の外部キー。
--   トップの社員（部長）は上司がいないので manager_id は NULL になる。
-- ---------------------------------------------------------------------
CREATE TABLE employees (
    employee_id     INT             NOT NULL AUTO_INCREMENT COMMENT '社員ID（主キー）',
    employee_name   VARCHAR(50)     NOT NULL COMMENT '社員名',
    department_id   INT             NOT NULL COMMENT '所属部署ID（departments.department_idを参照）',
    position        VARCHAR(30)     NOT NULL COMMENT '役職（部長/課長/主任/一般）',
    hire_date       DATE            NOT NULL COMMENT '入社日',
    salary          INT             NOT NULL COMMENT '給与（月給、円）',
    manager_id      INT             NULL     COMMENT '上司の社員ID（自己参照、トップはNULL）',
    PRIMARY KEY (employee_id),
    CONSTRAINT fk_employees_department
        FOREIGN KEY (department_id) REFERENCES departments (department_id),
    CONSTRAINT fk_employees_manager
        FOREIGN KEY (manager_id) REFERENCES employees (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='社員マスタ';

-- ---------------------------------------------------------------------
-- categories（商品カテゴリ）
-- ---------------------------------------------------------------------
CREATE TABLE categories (
    category_id     INT             NOT NULL AUTO_INCREMENT COMMENT 'カテゴリID（主キー）',
    category_name   VARCHAR(50)     NOT NULL COMMENT 'カテゴリ名',
    PRIMARY KEY (category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品カテゴリマスタ';

-- ---------------------------------------------------------------------
-- products（商品）
-- ---------------------------------------------------------------------
CREATE TABLE products (
    product_id      INT             NOT NULL AUTO_INCREMENT COMMENT '商品ID（主キー）',
    product_name    VARCHAR(100)    NOT NULL COMMENT '商品名',
    category_id     INT             NOT NULL COMMENT 'カテゴリID（categories.category_idを参照）',
    price            INT            NOT NULL COMMENT '販売価格（円、税抜）',
    stock_quantity  INT             NOT NULL DEFAULT 0 COMMENT '在庫数',
    PRIMARY KEY (product_id),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES categories (category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品マスタ';

-- ---------------------------------------------------------------------
-- customers（顧客）
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id      INT            NOT NULL AUTO_INCREMENT COMMENT '顧客ID（主キー）',
    customer_name    VARCHAR(50)    NOT NULL COMMENT '顧客名',
    prefecture       VARCHAR(20)    NOT NULL COMMENT '都道府県',
    email            VARCHAR(100)   NOT NULL COMMENT 'メールアドレス',
    registered_date  DATE           NOT NULL COMMENT '会員登録日',
    PRIMARY KEY (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='顧客マスタ';

-- ---------------------------------------------------------------------
-- orders（注文）
--   employee_id は注文対応をした社員（電話・店頭注文など）。
--   Webサイトから直接注文された場合は担当社員がいないため NULL になる。
--   → LEFT JOIN や「担当者がいない注文」を探す演習で使う。
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    order_id        INT             NOT NULL AUTO_INCREMENT COMMENT '注文ID（主キー）',
    customer_id     INT             NOT NULL COMMENT '注文した顧客ID（customers.customer_idを参照）',
    employee_id     INT             NULL     COMMENT '対応した社員ID（Web直販の場合はNULL）',
    order_date      DATE            NOT NULL COMMENT '注文日',
    status          VARCHAR(20)     NOT NULL COMMENT '注文ステータス（処理中/発送済み/完了/キャンセル）',
    PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
    CONSTRAINT fk_orders_employee
        FOREIGN KEY (employee_id) REFERENCES employees (employee_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='注文';

-- ---------------------------------------------------------------------
-- order_items（注文明細）
--   1つの注文（orders）に対して、複数の商品明細行（order_items）がぶら下がる
--   「1対多」の代表的な構造。unit_price は注文された時点の単価を保存する
--   （後で商品価格が変わっても、過去の注文金額が変わらないようにするため）。
-- ---------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id   INT             NOT NULL AUTO_INCREMENT COMMENT '注文明細ID（主キー）',
    order_id        INT             NOT NULL COMMENT '注文ID（orders.order_idを参照）',
    product_id      INT             NOT NULL COMMENT '商品ID（products.product_idを参照）',
    quantity        INT             NOT NULL COMMENT '数量',
    unit_price      INT             NOT NULL COMMENT '注文時点の単価（円）',
    PRIMARY KEY (order_item_id),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id) REFERENCES products (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='注文明細';
