from api.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()
try:
    db.execute(text("ALTER TABLE pricing_history ADD COLUMN promo_name VARCHAR"))
    db.execute(text("ALTER TABLE pricing_history ADD COLUMN promo_pct NUMERIC(6,4)"))
    db.commit()
    print("Database altered successfully!")
except Exception as e:
    print("Error:", e)
    db.rollback()
finally:
    db.close()
