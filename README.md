#  Leami

Leami je informacioni sistem za restoran koji omogućava digitalizaciju procesa naručivanja jela,pravljenja narudžbi, rezervacija i ostavljanja recenzija.  
Sistem obuhvata **desktop i mobilnu aplikaciju**, te backend razvijen u **ASP.NET Core**.

---

## 🚀 Upute za pokretanje

### 🔹 Backend setup
1. Klonirati **Leami** repozitorij.  
2. Env file se nalazi u rootu direktorija **`Leami`**
3. Env file se nalazi u rootu direktorija **`ReservationEmailConsumer`**
4. Env file se nalazi u rootu direktorija **`leami_mobile`**
5. U rootu foldera **`Leami`**  otvoriti terminal i pokrenuti komandu:

```bash
docker compose up --build
```

Sačekati da se sve uspješno build-a.⏳

Frontend aplikacije
Vratiti se u root folder i locirati fit-build-2025-08-09.zip arhivu.

Extract arhive daje dva foldera: Release i flutter-apk.

U Release folderu pokrenuti:
leami_desktop.exe

U flutter-apk folderu nalazi se fajl:
app-release.apk
Prenijeti ga na Android emulator ili fizički uređaj.

⚠️ Deinstalirati staru verziju aplikacije ukoliko je već instalirana.

Nakon instalacije obje aplikacije, prijaviti se pomoću test kredencijala.

🔐 Kredencijali za prijavu

Administrator

Email: admin@leami.local

Lozinka: test


Radnik

Email: employee@leami.local

Lozinka: test


Admin i employee se pokreću na desktop strani.

Gost:

Email:guest@leami.local

Lozinka: test

Gost se pokreće na mobilnoj strani.


💳 Stripe integracija

Plaćanje narudžbi omogućeno je kroz stripe integraciju u mobilnoj aplikaciji.

Kredencijali koji se upisuju su :

Card infromation: 4242 42424 4242 42424
MM/YY: 09/26
CVC:123
Odabir države: bilo koja :D


## 🔧 Mikroservis funkcionalnosti

Aplikacija koristi RabbitMQ mikroservis za automatsko slanje email obavještenja u sljedećim slučajevima:

Kada admin tj. vlasnik restorana odobri ili odbije rezervaciju korisnika.

## 🛠️ Tehnologije

**Backend:** ASP.NET Core (C#), EF Core  
**Autentifikacija & autorizacija:** ASP.NET Core Identity (IdentityUser) i JWT (JSON Web Tokens)  
**Frontend:** Flutter (desktop i mobilna aplikacija)  
**Baza podataka:** SQL Server  
**Message Broker:** RabbitMQ  
**Plaćanje:** Stripe  
**Containerization:** Docker




📌 Projekt razvijen u sklopu predmeta Razvoj softvera 2 na Fakultetu informacijskih tehnologija Mostar.
