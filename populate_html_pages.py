#!/usr/bin/env python3
"""
Generates one HTML page per place listed in happy_hours_global.Name
Requirements: pip install mysql-connector-python
Notes:
 - opening_hours, happy_hours, photos: matched by business_id -> businesses.id
 - good_to_know: matched by good_to_know.id == businesses.id (per your instruction)
 - offers: matched by offers.business_slug == slug(businesses.name)
"""

import os
import re
import mysql.connector
from mysql.connector import Error

# --- DB credentials (the ones you provided) ---
DB_HOST = "mysql2-p2.ezhostingserver.com"
DB_USER = "sanjay"
DB_PASS = "BU@R9gr2971{"
DB_NAME = "interview_helper"

OUTPUT_DIR = "output_html"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def slugify_filename(name: str) -> str:
    name = name.strip()
    name = re.sub(r"[^\w\s-]", "", name)         # remove non-word chars
    name = re.sub(r"[-\s]+", "_", name)          # spaces and dashes -> underscore
    return name[:120] or "place"

def slug_for_offers(name: str) -> str:
    s = name.lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    s = re.sub(r"-{2,}", "-", s)
    return s.strip("-")

def embed_map_url(address: str) -> str:
    if not address:
        return "https://www.google.com/maps"
    q = re.sub(r"\s+", "+", address.strip())
    return f"https://www.google.com/maps?q={q}&output=embed"

def safe(val, default=""):
    return "" if val is None else str(val)

def fetch_one(cursor, query, params):
    cursor.execute(query, params)
    return cursor.fetchone()

def fetch_all(cursor, query, params):
    cursor.execute(query, params)
    return cursor.fetchall()

def _format_label(label: str) -> str:
    if not label:
        return ""
    cleaned = label.rstrip().rstrip(":").rstrip()
    return f"{cleaned}: "

def build_html(name, business, opening_hours, happy_hours, photos, offers, good_to_know, global_row):
    # Basic fields
    tagline = safe(business.get("tagline", "")) if business else ""
    address_line1 = safe(business.get("address_line1", "")) if business else ""
    about_html = business.get("about_html", "") if business and business.get("about_html") else ""

    # Phone from happy_hours_global
    telephone = ""
    if global_row:
        telephone = safe(global_row.get("Telephone") or global_row.get("telephone") or "")

    # Opening hours fallback
    if opening_hours:
        first_open = opening_hours[0]
        open_time = safe(first_open.get("open_time", ""))
        close_time = safe(first_open.get("close_time", ""))
    else:
        open_time = close_time = ""

    # Happy hours fallback
    if happy_hours:
        first_hh = happy_hours[0]
        hh_start = safe(first_hh.get("start_time", ""))
        hh_end = safe(first_hh.get("end_time", ""))
        hh_description = safe(first_hh.get("description", ""))
    else:
        hh_start = hh_end = hh_description = ""

    # Photo
    photo_url = safe(photos[0].get("url")) if photos else "https://placehold.co/400x300/f3f4f6/6b7280?text=Venue+Photos"

    # Address short (first 3 words)
    address_short = " ".join(address_line1.split()[:3]) if address_line1 else ""

    # Map url
    map_url = embed_map_url(address_line1)

    # Opening hours list
    weekdays = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    days_html = ""
    if opening_hours:
        for i, day in enumerate(weekdays):
            if i < len(opening_hours):
                row = opening_hours[i]
                days_html += f'<li class="hours-row"><span class="day">{day}</span><span class="time">{safe(row.get("open_time",""))} – {safe(row.get("close_time",""))}</span></li>\n'
            else:
                days_html += f'<li class="hours-row"><span class="day">{day}</span><span class="time">{open_time} – {close_time}</span></li>\n'
    else:
        for day in weekdays:
            days_html += f'<li class="hours-row"><span class="day">{day}</span><span class="time">{open_time} – {close_time}</span></li>\n'

    # Offers HTML
    offers_html = ""
    if offers:
        for o in offers:
            title = safe(o.get("title",""))
            desc = safe(o.get("description",""))
            offers_html += f'<li><span>{title}</span><span class="badge">{desc}</span></li>\n'
    else:
        offers_html = '<li><span>No current offers</span><span class="muted">—</span></li>\n'

    # Good to know HTML
    gtk_html = ""
    if good_to_know:
        for g in good_to_know:
            label = _format_label(safe(g.get("label","")))
            value = safe(g.get("value",""))
            gtk_html += f'<li class="gtk-item"><span class="gtk-label">{label}</span><span class="gtk-value">{value}</span></li>\n'
    else:
        gtk_html = '<li class="gtk-item"><span class="gtk-label">Info: </span><span class="gtk-value">—</span></li>\n'

    # Compose HTML
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{name} | Bangkok</title>
  <meta name="description" content="{name} in Bangkok — hours, happy hours, offers, photos, map, and contact details." />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root{{--card:#f9fafb;--muted:#6b7280;--brand-2:#12a56a;--shadow:0 2px 8px rgba(0,0,0,0.08);--radius:12px}}
    *{{box-sizing:border-box}}
    html,body{{height:100%}}
    html{{scroll-padding-top:110px}} /* prevent sticky header from hiding titles */
    body{{margin:0;font-family:Inter,system-ui,Arial;color:#1f2937;background:#fff;line-height:1.6;padding-top:120px}}
    a{{color:#2563eb;text-decoration:none}}
    .container{{width:min(1120px,92vw);margin:0 auto;padding:0 12px}}

    /* Fixed two-line header */
    header{{position:fixed;top:0;left:0;right:0;z-index:999;background:#fff;border-bottom:1px solid #e5e7eb;box-shadow:0 2px 4px rgba(0,0,0,0.04);display:flex;flex-direction:column}}
    .header-top{{font-weight:800;font-size:20px;text-align:center;padding:10px 0;border-bottom:1px solid #e5e7eb}}
    .nav{{display:flex;justify-content:center;padding:10px 0}}
    
    /* wrapper enables scroll */
    .nav-wrapper {{
      overflow-x: auto;                  /* horizontal scroll */
      -webkit-overflow-scrolling: touch; /* smooth scroll on iOS */
      width: 100%;
    }}

    .nav-links{{display:flex;gap:16px;flex-wrap:nowrap;white-space:nowrap;padding: 0 8px;}}
    
    .nav-wrapper::-webkit-scrollbar {{
        display: none; /* hide scrollbar */
      }}

    .nav-links a{{color:var(--muted);text-decoration:none;font-size:15px;padding:6px 10px;flex-shrink:0}}
    .nav-links a:hover{{text-decoration:underline}}

    /* Mobile adjustments */
    @media (max-width:600px){{
      .nav-links{{gap:12px}}
      .nav-links a{{font-size:14px;padding:4px 8px}}
    }}

    .hero{{padding:48px 0}}
    .hero-card{{background:var(--card);border-radius:20px;padding:22px;display:grid;grid-template-columns:1.6fr 1fr;gap:18px;box-shadow:var(--shadow)}}
    .title{{font-size:clamp(28px,4vw,40px);margin:6px 0}}
    .sub{{color:var(--muted)}}
    .chip{{background:#eef2ff;border-radius:10px;padding:8px 10px;color:#4338ca;font-size:12px;margin-right:8px;display:inline-block}}
    .hero-img{{width:100%;height:100%;object-fit:cover;border-radius:12px}}

    .card{{background:var(--card);border-radius:var(--radius);padding:16px;box-shadow:var(--shadow);margin-bottom:14px}}
    .grid{{display:grid;grid-template-columns:1.1fr 1fr;gap:18px}}

    .list{{list-style:none;padding:0;margin:10px 0 0}}
    .muted{{color:var(--muted)}}
    .badge{{font-size:12px;padding:6px 8px;border-radius:8px;background:#dcfce7;color:#166534;border:1px solid #bbf7d0}}

    .hours-list{{list-style:none;padding:0;margin:10px 0 0}}
    .hours-row{{display:flex;align-items:center;gap:8px;padding:12px 0;border-bottom:1px dashed #e5e7eb}}
    .hours-row:last-child{{border-bottom:none}}
    .day{{font-weight:500}}
    .time{{margin-left:auto;text-align:right;color:#1f2937}}

    .gtk-list{{list-style:none;padding:0;margin:10px 0 0}}
    .gtk-item{{display:flex;align-items:center;gap:8px;padding:12px 0;border-bottom:1px dashed #e5e7eb}}
    .gtk-item:last-child{{border-bottom:none}}
    .gtk-label{{font-weight:600;white-space:nowrap;color:#1f2937}}
    .gtk-value{{color:#1f2937}}

    .map{{width:100%;height:280px;border:0;border-radius:12px}}
    footer{{color:var(--muted);padding:18px 0}}

    @media (max-width:900px){{.hero-card{{grid-template-columns:1fr}}.grid{{grid-template-columns:1fr}}body{{padding-top:130px}}}}
  </style>
</head>
<body>
  <header>
    <div class="header-top">Bangkok Happy Hours</div>
    <nav class="nav">
      <div class="nav-wrapper">
        <div class="nav-links">
          <a href="#about">About</a>
          <a href="#hours">Hours</a>
          <a href="#happyhour">Happy Hour</a>
          <a href="#offers">Offers</a>
          <a href="#map">Map</a>
          <a href="#contact">Contact</a>
          <a href="#goodtoknow">Good To Know</a>
        </div>
      </div>
    </nav>
  </header>

  <main>
    <section class="hero">
      <div class="container hero-card">
        <div>
          <h1 class="title">{name}</h1>
          <p class="sub">{tagline}</p>
          <div style="margin-top:12px">
            <span class="chip">Bangkok • {address_short}</span>
            <span class="chip">Open daily {open_time}–{close_time}</span>
            <span class="chip">Happy Hour {hh_start}–{hh_end}</span>
          </div>
        </div>
        <div class="hero-media">
          <img src="{photo_url}" alt="{name} photo" class="hero-img" />
        </div>
      </div>
    </section>

    <section id="about" class="container grid">
      <article class="card">
        <h3>About</h3>
        <div>{about_html}</div>
      </article>

      <aside id="hours" class="card">
        <h3>Opening Hours</h3>
        <ul class="hours-list">
{days_html}        </ul>
        <p class="meta muted">Note: Hours may vary on holidays and during special events.</p>
      </aside>
    </section>

    <section id="happyhour" class="container grid">
      <article class="card">
        <h3>Happy Hour</h3>
        <p class="meta muted">{hh_description}</p>
        <ul class="list">
          <li class="hours-row"><span>Daily</span><span class="time" style="color:var(--brand-2);font-weight:700">{hh_start} – {hh_end}</span></li>
        </ul>
      </article>

      <aside id="offers" class="card">
        <h3>Current Offers</h3>
        <ul class="list">
{offers_html}        </ul>
      </aside>
    </section>

    <section id="map" class="container" style="margin-top:14px">
      <div class="card">
        <h3>Location</h3>
        <p>{address_line1}</p>
        <iframe class="map" loading="lazy" src="{map_url}" allowfullscreen></iframe>
      </div>

      <aside id="contact" class="card" style="margin-top:14px">
        <h3>Contact</h3>
        <div style="margin-bottom:8px">
          <div class="muted">Phone: </div>
          <div><a href="tel:{telephone}">{telephone}</a></div>
        </div>
        <div class="muted">Address: </div>
        <div>{address_line1}</div>
      </aside>
    </section>

    <section id="goodtoknow" class="container" style="margin-top:14px">
      <div class="card">
        <h3>Good to Know</h3>
        <ul class="gtk-list">
{gtk_html}        </ul>
      </div>
    </section>
  </main>

  <footer class="container">
    <div>© 2025 Bangkok Happy Hours • This is a static informational page.</div>
  </footer>
</body>
</html>
"""
    return html

def main():
    try:
        conn = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASS,
            database=DB_NAME,
            charset='utf8mb4'
        )
        cursor = conn.cursor(dictionary=True)

        # Get all names from happy_hours_global
        cursor.execute("SELECT Name FROM happy_hours_global")
        rows = cursor.fetchall()
        names = [r['Name'] for r in rows if r.get('Name')]

        if not names:
            print("No names found in happy_hours_global.")
            return

        for place_name in names:
            print("Processing:", place_name)

            # Find business row by name
            business = fetch_one(cursor, "SELECT * FROM businesses WHERE name = %s LIMIT 1", (place_name,))
            if not business:
                print("  -> business record not found for:", place_name)
                continue
            business_id = business.get("id")

            # happy_hours_global row (to get telephone etc.)
            global_row = fetch_one(cursor, "SELECT * FROM happy_hours_global WHERE Name = %s LIMIT 1", (place_name,))

            # opening_hours matched by business_id -> businesses.id
            opening_hours = fetch_all(cursor, "SELECT * FROM opening_hours WHERE business_id = %s ORDER BY id", (business_id,))

            # happy_hours matched by business_id
            happy_hours = fetch_all(cursor, "SELECT * FROM happy_hours WHERE business_id = %s ORDER BY id", (business_id,))

            # photos matched by business_id
            photos = fetch_all(cursor, "SELECT * FROM photos WHERE business_id = %s ORDER BY id", (business_id,))

            # good_to_know matched where good_to_know.id == businesses.id (per your instruction)
            good_to_know = fetch_all(cursor, "SELECT * FROM good_to_know WHERE id = %s ORDER BY id", (business_id,))

            # offers: match business_slug to slug(businesses.name)
            offers_slug = slug_for_offers(place_name)
            offers = fetch_all(cursor, "SELECT * FROM offers WHERE business_slug = %s ORDER BY id", (offers_slug,))

            # Generate HTML page
            html = build_html(place_name, business or {}, opening_hours or [], happy_hours or [], photos or [], offers or [], good_to_know or [], global_row or {})

            fname = slugify_filename(place_name) + ".html"
            out_path = os.path.join(OUTPUT_DIR, fname)
            with open(out_path, "w", encoding="utf-8") as f:
                f.write(html)
            print("  -> written:", out_path)

        cursor.close()
        conn.close()
        print("Done. Files are in the", OUTPUT_DIR, "directory.")

    except Error as e:
        print("MySQL error:", e)
    except Exception as ex:
        print("Error:", ex)

if __name__ == "__main__":
    main()