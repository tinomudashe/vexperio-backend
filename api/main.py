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
