#!/bin/bash
# Mensimulasikan beban aplikasi toko online (tanpa query lambat buatan):
# lihat riwayat pesanan pelanggan, ringkasan belanja, buat pesanan, kurangi stok.
# Pemakaian: ./scripts/load-test.sh [durasi_detik] [jumlah_worker]
#            default: 120 detik x 20 worker
set -e
cd "$(dirname "$0")/.."
# tr -d '\r' supaya aman walaupun .env disimpan dengan Notepad (format baris Windows)
set -a; source <(tr -d '\r' < .env); set +a
DURATION="${1:-120}"
WORKERS="${2:-20}"

echo "Menjalankan $WORKERS worker selama $DURATION detik..."
echo "Biarkan dashboard Grafana terbuka selama proses berjalan."

docker exec \
  -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" \
  -e DB="$MYSQL_DATABASE" -e DURATION="$DURATION" -e WORKERS="$WORKERS" \
  mysql bash -c '
worker() {
  local n=0 end=$((SECONDS + DURATION))
  while [ $SECONDS -lt $end ]; do
    cid=$((RANDOM % 2000 + 1))
    pid=$((RANDOM % 5 + 1))
    mysql -uroot "$DB" -e "
      SELECT id, product_id, total, created_at FROM orders
        WHERE customer_id = $cid ORDER BY created_at DESC LIMIT 10;
      SELECT c.city, COUNT(*), SUM(o.total) FROM orders o
        JOIN customers c ON c.id = o.customer_id
        WHERE o.customer_id = $cid GROUP BY c.city;
      INSERT INTO orders (customer_id, product_id, qty, total) VALUES ($cid, $pid, 1, 85000);
      UPDATE products SET stock = stock - 1 WHERE id = $pid;" > /dev/null
    n=$((n + 1))
  done
  echo $n
}
for ((w = 1; w <= WORKERS; w++)); do worker > /tmp/worker_$w & done
wait
total=0; for f in /tmp/worker_*; do total=$((total + $(cat "$f"))); done
rm -f /tmp/worker_*
echo "Total transaksi: $total dalam $DURATION detik (rata-rata $((total / DURATION)) transaksi/detik)"
'
echo "Selesai. Lihat hasilnya di http://localhost:3000"
