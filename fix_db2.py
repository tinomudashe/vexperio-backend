from api.database import SessionLocal
from sqlalchemy import text

db = SessionLocal()
try:
    db.execute(text("ALTER TABLE pricing_history ADD COLUMN change_details TEXT"))
    db.execute(text("ALTER TABLE pricing_history ADD COLUMN reviewer_comments TEXT"))
    db.commit()
    print("Database altered successfully!")
except Exception as e:
    print("Error:", e)
    db.rollback()
finally:
    db.close()
