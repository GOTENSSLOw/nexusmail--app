import re

def sanitize_username(username: str) -> str:
    username = username.lower().strip()
    username = re.sub(r'[^a-z0-9]', '', username)
    return username[:30]

def is_valid_username(username: str) -> bool:
    if not username or len(username) < 3:
        return False
    if username[0].isdigit():
        return False
    return True