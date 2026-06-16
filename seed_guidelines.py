import requests

payload = {
    "general": [
        {"key_name": "Duration", "value_text": "total, including transfer time each way if applicable."},
        {"key_name": "Shared tour notice", "value_text": "max number of passengers (e.g., 'This is a shared tour with a maximum of 45 passengers')."},
        {"key_name": "Guide presence", "value_text": "clarify if guide is not present throughout."}
    ],
    "platforms": {
        "Vexperio": [
            {"key_name": "Option name", "value_text": "MAJESTIC PRINCESS; CARNIVAL LEGEND - 10H Tour"},
            {"key_name": "Duration", "value_text": "Full-day tour of approximately 10-11 hours"}
        ],
        "GYG": [
            {"key_name": "Option description", "value_text": "Shared 10-11h tour (max 45 pax). Transfers 3-3.5h each way. Guide joins in Paris."}
        ]
    },
    "ports": {
        "MSM": [
            {"key_name": "Option title", "value_text": "Ticket for a Shared Tour"},
            {"key_name": "Duration", "value_text": "Full-day tour of approx. 10 -11h"},
            {"key_name": "Packed Lunch included", "value_text": "Homemade packed lunch with a ham and cheese baguette"}
        ],
        "D-day": [
            {"key_name": "Option title", "value_text": "ship name -> NORWEGIAN SKY"},
            {"key_name": "Duration", "value_text": "Full-day tour of approx. 9 - 10h"}
        ]
    },
    "updated_by": "System Seed"
}

r = requests.post("http://localhost:8000/guidelines/sync", json=payload)
print(r.status_code, r.text)
