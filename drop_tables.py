from api.database import engine
from sqlalchemy import text

with engine.connect() as c:
    c.execute(text("DROP TABLE IF EXISTS guideline_attribute CASCADE;"))
    c.execute(text("DROP TABLE IF EXISTS guideline CASCADE;"))
    c.commit()
