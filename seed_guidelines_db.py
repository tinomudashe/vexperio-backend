from api.database import get_db, engine, Base
from api.models import Guideline, GuidelineAttribute

print("Dropping old tables...")
GuidelineAttribute.__table__.drop(engine, checkfirst=True)
Guideline.__table__.drop(engine, checkfirst=True)

print("Creating new tables...")
Guideline.__table__.create(engine, checkfirst=True)
GuidelineAttribute.__table__.create(engine, checkfirst=True)

db = next(get_db())

payload = {
    "general": [
        {"key": "Duration", "val": "total, including transfer time each way if applicable."},
        {"key": "Shared tour notice", "val": "max number of passengers (e.g., 'This is a shared tour with a maximum of 45 passengers')."},
        {"key": "Guide presence", "val": "clarify if guide is not present throughout."}
    ],
    "platforms": {
        "Vexperio": [
            {"key": "Option name", "val": "MAJESTIC PRINCESS; CARNIVAL LEGEND - 10H Tour"},
            {"key": "Duration", "val": "Full-day tour of approximately 10-11 hours"}
        ],
        "GYG": [
            {"key": "Option description", "val": "Shared 10-11h tour (max 45 pax). Transfers 3-3.5h each way. Guide joins in Paris."}
        ]
    },
    "ports": {
        "MSM": [
            {"key": "Option title", "val": "Ticket for a Shared Tour"},
            {"key": "Duration", "val": "Full-day tour of approx. 10 -11h"},
            {"key": "Packed Lunch included", "val": "Homemade packed lunch with a ham and cheese baguette"}
        ],
        "D-day": [
            {"key": "Option title", "val": "ship name -> NORWEGIAN SKY"},
            {"key": "Duration", "val": "Full-day tour of approx. 9 - 10h"}
        ]
    }
}

g = Guideline(type="general", entity_name="General")
for i, item in enumerate(payload["general"]):
    g.attributes.append(GuidelineAttribute(key_name=item["key"], value_text=item["val"], order_index=i))
db.add(g)

for plat_name, attrs in payload["platforms"].items():
    g = Guideline(type="platform", entity_name=plat_name)
    for i, item in enumerate(attrs):
        g.attributes.append(GuidelineAttribute(key_name=item["key"], value_text=item["val"], order_index=i))
    db.add(g)

for port_name, attrs in payload["ports"].items():
    g = Guideline(type="port_excursion", entity_name=port_name)
    for i, item in enumerate(attrs):
        g.attributes.append(GuidelineAttribute(key_name=item["key"], value_text=item["val"], order_index=i))
    db.add(g)

db.commit()
print("Seeded guidelines.")
