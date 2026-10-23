#!/bin/bash
# Tuning: tambahkan index di orders.customer_id lalu jalankan load-test lagi,
# bandingkan grafik "Slow queries" dan "Tabel temporer & sort" sebelum vs sesudah.
set -e
cd "$(dirname "$0")/.."
set -a; source <(tr -d '\r' < .env); set +a

docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql mysql -uroot "$MYSQL_DATABASE" -e "
  SELECT 'SEBELUM index' AS tahap;
  EXPLAIN SELECT * FROM orders WHERE customer_id = 42\G
  CREATE INDEX idx_orders_customer ON orders(customer_id);
  SELECT 'SESUDAH index' AS tahap;
  EXPLAIN SELECT * FROM orders WHERE customer_id = 42\G"

echo "Index idx_orders_customer dibuat. Jalankan ./scripts/load-test.sh lagi untuk membandingkan."
