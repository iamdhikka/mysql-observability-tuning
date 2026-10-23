-- Skema toko online + data awal, supaya beban kerja dan grafik realistis.
-- Dijalankan otomatis terhadap database MYSQL_DATABASE di file .env.

SET SESSION cte_max_recursion_depth = 10000;

CREATE TABLE customers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  city VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  price DECIMAL(12,2) NOT NULL,
  stock INT NOT NULL DEFAULT 0
);

-- Sengaja TANPA index di customer_id: kondisi awal yang akan di-tuning
CREATE TABLE orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  product_id INT NOT NULL,
  qty INT NOT NULL,
  total DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO products (name, price, stock) VALUES
  ('Kopi Arabika 250g', 85000, 100000), ('Teh Melati', 25000, 100000),
  ('Gula Aren 500g', 32000, 100000), ('Madu Hutan 350ml', 120000, 100000),
  ('Keripik Singkong', 15000, 100000);

-- 2.000 pelanggan
INSERT INTO customers (name, city)
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 2000)
SELECT CONCAT('Pelanggan ', n),
       ELT(1 + (n % 5), 'Jakarta', 'Bandung', 'Surabaya', 'Medan', 'Makassar')
FROM seq;

-- 500.000 pesanan (1.000 x 500 baris), tersebar dalam 1 tahun terakhir
INSERT INTO orders (customer_id, product_id, qty, total, created_at)
WITH RECURSIVE
  a(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM a WHERE n < 1000),
  b(n) AS (SELECT 0 UNION ALL SELECT n + 1 FROM b WHERE n < 499)
SELECT 1 + ((b.n * 1000 + a.n) * 7919) % 2000,
       1 + ((b.n * 1000 + a.n) % 5),
       1 + ((b.n * 1000 + a.n) % 4),
       (1 + ((b.n * 1000 + a.n) % 4)) * 25000,
       NOW() - INTERVAL ((b.n * 1000 + a.n) % 525600) MINUTE
FROM a CROSS JOIN b;
