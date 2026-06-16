import requests

url = "http://localhost:8080/pricing/17"
payload = {
    "price": 120.00,
    "promo_name": "SUMMER_SALE",
    "promo_pct": 0.15,
    "change_status": "Pending",
    "editor": "TestAgent"
}
headers = {
    "Content-Type": "application/json",
    "x-user-key": "TestAgent"
}

response = requests.patch(url, json=payload, headers=headers)
print("Status Code:", response.status_code)
print("Response:", response.json())
