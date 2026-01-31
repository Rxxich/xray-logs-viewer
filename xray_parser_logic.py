import argparse
import os
import re
import urllib.request
from collections import defaultdict
import geoip2.database

CITY_DB_PATH = "/tmp/GeoLite2-City.mmdb"
ASN_DB_PATH = "/tmp/GeoLite2-ASN.mmdb"

def color_text(text, color_code):
    return f"\033[{color_code}m{text}\033[0m"

def download_geoip_db():
    dbs = {
        CITY_DB_PATH: "https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb",
        ASN_DB_PATH: "https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb"
    }
    for path, url in dbs.items():
        if not os.path.exists(path):
            urllib.request.urlretrieve(url, path)

def extract_email_number(email):
    if email == "Unknown Email": return [float('inf'), email]
    numbers = re.findall(r"(\d+)", email)
    if numbers:
        return [int(numbers[0]), email]
    return [float('inf'), email]

def highlight_resource(resource):
    highlight_domains = {
        "mycdn.me", "mvk.com", "userapi.com", "vk-apps.com", "vk-cdn.me", "vk-cdn.net", "vk-portal.net", "vk.cc",
        "vk.com", "vk.company", "vk.design", "vk.link", "vk.me", "vk.team", "vkcache.com", "vkgo.app", "vklive.app",
        "vkmessenger.app", "vkmessenger.com", "vkuser.net", "vkuseraudio.com", "vkuseraudio.net", "vkuserlive.net",
        "vkuservideo.com", "vkuservideo.net", "yandex.aero", "yandex.az", "yandex.by", "yandex.co.il", "yandex.com",
        "yandex.com.am", "yandex.com.ge", "yandex.com.ru", "yandex.com.tr", "yandex.com.ua", "yandex.de", "yandex.ee",
        "yandex.eu", "yandex.fi", "yandex.fr", "yandex.jobs", "yandex.kg", "yandex.kz", "yandex.lt", "yandex.lv",
        "yandex.md", "yandex.net", "yandex.org", "yandex.pl", "yandex.ru", "yandex.st", "yandex.sx", "yandex.tj",
        "yandex.tm", "yandex.ua", "yandex.uz", "yandexcloud.net", "yastatic.net", "dodois.com", "dodois.io", "ekatox-ru.com",
        "jivosite.com", "showip.net", "kaspersky-labs.com", "kaspersky.com"
    }
    questinable_domains = {"alicdn.com", "xiaomi.net", "xiaomi.com", "mi.com", "miui.com"}
    if any(resource == domain or resource.endswith("." + domain) for domain in highlight_domains) \
            or re.search(r"\.ru$|\.ru.com$|\.su$|\.by$|[а-яА-Я]", resource) \
            or "xn--" in resource:
        return color_text(resource, "91")
    if any(resource == domain or resource.endswith("." + domain) for domain in questinable_domains) \
            or re.search(r"\.cn$|\.citic$|\.baidu$|\.sohu$|\.unicom$", resource):
        return color_text(resource, "93")
    return resource

def get_region_and_asn(ip, city_reader, asn_reader):
    try:
        res = city_reader.city(ip)
        country = res.country.name or "Unknown"
        res_asn = asn_reader.asn(ip)
        asn = f"AS{res_asn.autonomous_system_number} {res_asn.autonomous_system_organization}"
        return f"{country}, {asn}"
    except: return "Unknown Location"

def parse_log_entry(log, filter_ip_resource, city_reader):
    # ВОЗВРАЩЕНО ОРИГИНАЛЬНОЕ РЕГУЛЯРНОЕ ВЫРАЖЕНИЕ
    pattern = re.compile(
        r".*?(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)?) "
        r"from (?P<ip>(?:[0-9a-fA-F:]+|\d+\.\d+\.\d+\.\d+|@|unix:@))?(?::\d+)? accepted (?:(tcp|udp):)?(?P<resource>[\w\.-]+(?:\.\w+)*|\d+\.\d+\.\d+\.\d+):\d+ "
        r"\[(?P<destination>[^\]]+)\](?: email: (?P<email>\S+))?"
    )
    match = pattern.match(log)
    if match:
        ip = match.group("ip") or "Unknown IP"
        email = match.group("email") or "Unknown Email"
        resource = match.group("resource")
        
        ipv4_pattern = re.compile(r"^(?:\d{1,3}\.){3}\d{1,3}$")
        if ipv4_pattern.match(resource):
            if filter_ip_resource: return None
            try:
                country = city_reader.city(resource).country.name
                if country in ["Russia", "Belarus"]:
                    resource = color_text(f"{resource} ({country})", "91")
                else: resource = f"{resource} ({country})"
            except: pass
        else:
            resource = highlight_resource(resource)
        return ip, email, resource
    return None

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", required=True)
    parser.add_argument("--summary", action="store_true")
    parser.add_argument("--ip", action="store_true")
    parser.add_argument("--online", action="store_true")
    parser.add_argument("--search", help="Search query")
    args = parser.parse_args()

    if not os.path.exists(args.path):
        print(color_text(f"Файл {args.path} не найден.", "31"))
        return

    download_geoip_db()
    with geoip2.database.Reader(CITY_DB_PATH) as city_r, geoip2.database.Reader(ASN_DB_PATH) as asn_r:
        with open(args.path, "r") as f:
            lines = f.readlines()

        parsed_data = []
        for line in lines:
            p = parse_log_entry(line, False if (args.ip or args.summary or args.online or args.search) else True, city_r)
            if p: parsed_data.append(p)

        if not parsed_data:
            print(color_text("Данные в логе найдены, но они не соответствуют формату Xray или пусты.", "33"))
            return

        if args.online:
            ip_last_email = {p[0]: p[1] for p in parsed_data}
            active_ips = set()
            for line in os.popen("netstat -an | grep ESTABLISHED").read().splitlines():
                parts = line.split()
                if len(parts) > 4: active_ips.add(parts[4].rsplit(':', 1)[0])
            found = active_ips.intersection(ip_last_email.keys())
            print(color_text("--- ONLINE ---", "92"))
            for ip in sorted(found):
                print(f"Email: {color_text(ip_last_email[ip], '92')} | IP: {ip} ({get_region_and_asn(ip, city_r, asn_r)})")

        elif args.search:
            s_q = args.search.lower()
            res_data = defaultdict(lambda: defaultdict(set))
            for ip, email, res in parsed_data:
                if s_q in res.lower() or s_q in ip.lower() or s_q in email.lower():
                    res_data[email][ip].add(res)
            for email in sorted(res_data.keys(), key=extract_email_number):
                print(f"User: {color_text(email, '92')}")
                for ip, resources in res_data[email].items():
                    print(f"  IP: {color_text(ip, '94')} ({get_region_and_asn(ip, city_r, asn_r)})")
                    for r in resources: print(f"    -> {r}")

        elif args.summary:
            summary = defaultdict(set)
            for ip, email, res in parsed_data: summary[email].add(ip)
            for email in sorted(summary.keys(), key=extract_email_number):
                ips = summary[email]
                print(f"User: {color_text(email, '92')} | Uniq IPs: {len(ips)}")
                for ip in sorted(ips): print(f"  - {ip} ({get_region_and_asn(ip, city_r, asn_r)})")

        else:
            final = defaultdict(lambda: defaultdict(set))
            for ip, email, res in parsed_data: final[email][ip].add(res)
            for email in sorted(final.keys(), key=extract_email_number):
                print(f"User: {color_text(email, '92')}")
                for ip, resources in final[email].items():
                    print(f"  IP: {color_text(ip, '94')} ({get_region_and_asn(ip, city_r, asn_r)})")
                    for r in sorted(resources): print(f"    -> {r}")

if __name__ == "__main__":
    main()

