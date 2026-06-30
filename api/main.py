from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.database import engine
from api import models
from api import history  # registers audit-log session listeners
from api.routers import (
    tours, platforms, schedules, departures,
    pricing, workflow, reference, media, users, guidelines
)

# models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Vexperio Tour Operations API",
    description="Manages tours, platform listings, schedules, departures, pricing and the change review workflow.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def _editor_ctx(request, call_next):
    """Stash the X-Editor header so the audit listener can attribute changes."""
    tok = history.current_editor.set(request.headers.get("X-Editor") or None)
    try:
        return await call_next(request)
    finally:
        history.current_editor.reset(tok)

app.include_router(tours.router)
app.include_router(platforms.router)
app.include_router(schedules.router)
app.include_router(departures.router)
app.include_router(pricing.router)
app.include_router(workflow.router)
app.include_router(reference.router)
app.include_router(media.router)
app.include_router(users.router)
app.include_router(guidelines.router)


@app.get("/", tags=["health"])
def root():
    return {"status": "ok", "service": "Vexperio API"}


@app.get("/health", tags=["health"])
def health():
    return {"status": "ok"}


from fastapi import Depends
from api.database import get_db

@app.get("/migrate-platforms", tags=["migration"])
def migrate_platforms(db: "sqlalchemy.orm.Session" = Depends(get_db)):
    from sqlalchemy import text
    try:
        # Create columns (no colons here so safe to use text directly)
        columns_sql = [
            "ALTER TABLE platform ADD COLUMN IF NOT EXISTS short_code TEXT;",
            "ALTER TABLE platform ADD COLUMN IF NOT EXISTS icon_url TEXT;",
            "ALTER TABLE platform ADD COLUMN IF NOT EXISTS domain TEXT;",
            "ALTER TABLE platform ADD COLUMN IF NOT EXISTS supplier_url_prefix TEXT;",
            "ALTER TABLE platform ADD COLUMN IF NOT EXISTS valid_statuses JSON;",
            "ALTER TABLE platform ADD COLUMN IF NOT EXISTS id_placeholder TEXT;",
            "ALTER TABLE platform ADD COLUMN IF NOT EXISTS id_hint TEXT;",
            "ALTER TABLE platform ADD COLUMN IF NOT EXISTS color_theme TEXT;"
        ]
        for cmd in columns_sql:
            db.execute(text(cmd))
            
        # Update existing data using parameterized queries to avoid colon syntax issues in text()
        update_sql = text("""
            UPDATE platform 
            SET short_code = :sc, domain = :dom, supplier_url_prefix = :sup, 
                valid_statuses = CAST(:vs AS JSON), id_placeholder = :ph, color_theme = :ct 
            WHERE name = :name;
        """)
        
        updates = [
            {"name": "GetYourGuide", "sc": "GY", "dom": "getyourguide.com", "sup": "https://supplier.getyourguide.com", "vs": '["ACTIVE", "INACTIVE"]', "ph": "674024", "ct": "gyg"},
            {"name": "Viator", "sc": "VI", "dom": "viator.com", "sup": "https://supplier.viator.com", "vs": '["ACTIVE", "INACTIVE"]', "ph": "P138", "ct": "via"},
            {"name": "Vexperio", "sc": "VX", "dom": None, "sup": None, "vs": None, "ph": None, "ct": "vex"}
        ]
        
        for params in updates:
            db.execute(update_sql, params)
            
        # Handle PE which has multiple names
        update_pe_sql = text("""
            UPDATE platform 
            SET short_code = 'PE', domain = 'projectexpedition.com', 
                valid_statuses = CAST('["ACTIVE", "INACTIVE"]' AS JSON), id_placeholder = 'PRD...', color_theme = 'pe' 
            WHERE name IN ('PE', 'Project Expedition');
        """)
        db.execute(update_pe_sql)

        db.commit()
        return {"status": "success", "message": "Platform columns and metadata migrated successfully!"}
    except Exception as e:
        db.rollback()
        return {"status": "error", "message": str(e), "type": type(e).__name__}
