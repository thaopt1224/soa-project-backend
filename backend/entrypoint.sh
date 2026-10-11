#!/bin/sh
echo "Waiting for postgres..."
set -e  # Exit ngay nếu bất kỳ lệnh nào thất bại

# Thêm timeout để tránh loop vô hạn (ví dụ: 60 giây)
counter=0
while ! nc -z $DB_URL $DB_PORT; do
    sleep 0.1
    counter=$((counter + 1))
    if [ $counter -ge 600 ]; then  # 600 * 0.1s = 60s
        echo "Timeout: Không thể kết nối PostgreSQL sau 60 giây."
        exit 1
    fi
done
echo "PostgreSQL started"


# Chỉ reset + seed DB khi RESET_DB=true (docker-compose-dev / migrate qua bastion).
# ECS không set biến này → task restart/autoscale không xoá dữ liệu trên RDS.
if [ "${RESET_DB:-false}" = "true" ]; then
    python manage.py recreate_db
    python manage.py seed_db
fi

gunicorn -b 0.0.0.0:$PORT manage:app