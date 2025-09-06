using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using DotNetEnv;
using Leami.Model.Entities;
using Leami.Services.Database;
using Leami.Services.Database.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Hosting;
namespace LeamiWebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class SeedController : ControllerBase
    {
        private readonly LeamiDbContext _db;

        // Statusi rezervacija
        private const int RES_STATUS_REJECTED = 0;
        private const int RES_STATUS_CONFIRMED = 1;
        private const int RES_STATUS_PENDING = 2;
        private readonly string _webRoot;
        private readonly string _contentRoot;
        public SeedController(LeamiDbContext db, IWebHostEnvironment env)
        {
            _db = db;

            _webRoot = string.IsNullOrWhiteSpace(env.WebRootPath)
                ? Path.Combine(env.ContentRootPath, "wwwroot")
                : env.WebRootPath;
            _contentRoot = env.ContentRootPath;

        }




        [HttpPost("init")]
        public async Task<IActionResult> Init()
        {
            // ===== ROLES =====
            if (!await _db.Roles.AnyAsync())
            {
                await _db.Roles.AddRangeAsync(new[]
                {
                    new Role { Name = "Admin",    NormalizedName = "ADMIN",    Description = "Administrator sistema", ConcurrencyStamp = Guid.NewGuid().ToString("N") },
                    new Role { Name = "Employee", NormalizedName = "EMPLOYEE", Description = "Zaposlenik restorana", ConcurrencyStamp = Guid.NewGuid().ToString("N") },
                    new Role { Name = "Guest",    NormalizedName = "GUEST",    Description = "Gost restorana",        ConcurrencyStamp = Guid.NewGuid().ToString("N") },
                });
                await _db.SaveChangesAsync();
            }

            // ===== USERS =====
            var hasher = new PasswordHasher<User>();
            if (!await _db.Users.AnyAsync())
            {
                var users = new List<User>
                {
                    MakeUser("admin",    "admin",    "Admin",  "User",     "test", hasher),
                    MakeUser("employee", "employee", "Ema",    "Zaposlenik","test", hasher),
                    MakeUser("guest",     "guest",     "Koris",  "Nik",      "test", hasher),

                    // radi zahtjeva iz README-a:
                    MakeUser("desktop",  "desktop",  "Desk",   "Top",      "test", hasher),
                    MakeUser("mobile",   "mobile",   "Mobi",   "Le",       "test", hasher),

                    // još malo korisnika (gosti) radi volumena
                    MakeUser("lana",     "lana@leami.local",     "Lana",   "Kovač",    "test", hasher),
                    MakeUser("amir",     "amir@leami.local",     "Amir",   "Alić",     "test", hasher),
                    MakeUser("ivana",    "ivana@leami.local",    "Ivana",  "Marić",    "test", hasher),
                    MakeUser("marko",    "marko@leami.local",    "Marko",  "Babić",    "test", hasher),
                    MakeUser("jelena",   "jelena@leami.local",   "Jelena", "Tomić",    "test", hasher),
                };
                await _db.Users.AddRangeAsync(users);
                await _db.SaveChangesAsync();

                var roleAdmin = await _db.Roles.FirstAsync(r => r.Name == "Admin");
                var roleEmployee = await _db.Roles.FirstAsync(r => r.Name == "Employee");
                var roleGuest = await _db.Roles.FirstAsync(r => r.Name == "Guest");

                var map = new List<IdentityUserRole<int>>
                {
                    new IdentityUserRole<int> { UserId = users.First(u=>u.UserName=="admin").Id,    RoleId = roleAdmin.Id    },
                    new IdentityUserRole<int> { UserId = users.First(u=>u.UserName=="employee").Id, RoleId = roleEmployee.Id },
                    new IdentityUserRole<int> { UserId = users.First(u=>u.UserName=="guest").Id,     RoleId = roleGuest.Id    },
                    new IdentityUserRole<int> { UserId = users.First(u=>u.UserName=="desktop").Id,  RoleId = roleGuest.Id    },
                    new IdentityUserRole<int> { UserId = users.First(u=>u.UserName=="mobile").Id,   RoleId = roleGuest.Id    },
                    new IdentityUserRole<int> { UserId = users.First(u=>u.UserName=="lana").Id,     RoleId = roleGuest.Id    },
                    new IdentityUserRole<int> { UserId = users.First(u=>u.UserName=="amir").Id,     RoleId = roleGuest.Id    },
                    new IdentityUserRole<int> { UserId = users.First(u=>u.UserName=="ivana").Id,    RoleId = roleGuest.Id    },
                    new IdentityUserRole<int> { UserId = users.First(u=>u.UserName=="marko").Id,    RoleId = roleGuest.Id    },
                    new IdentityUserRole<int> { UserId = users.First(u=>u.UserName=="jelena").Id,   RoleId = roleGuest.Id    },
                };
                await _db.UserRoles.AddRangeAsync(map);
                await _db.SaveChangesAsync();
            }

            // ===== EMPLOYEE DETAILS (za employee) =====
            var employeeUser = await _db.Users.FirstAsync(u => u.UserName == "employee");
            if (!await _db.Set<EmployeeDetails>().AnyAsync(e => e.UserId == employeeUser.Id))
            {
                await _db.AddAsync(new EmployeeDetails
                {
                    UserId = employeeUser.Id,
                    JobTitle = "Konobar",
                    HireDate = DateTime.UtcNow.AddDays(-120),
                    Note = "Iskusan i brz"
                });
                await _db.SaveChangesAsync();
            }

            // ===== RESTAURANT INFO (singleton) =====
            if (!await _db.Set<RestaurantInfo>().AnyAsync())
            {
                var admin = await _db.Users.FirstAsync(u => u.UserName == "admin");
                await _db.RestaurantInfos.AddAsync(new RestaurantInfo
                {
                    Name = "Leami",
                    Description = "Janjetina je naš specijalitet, dođite i uvjerite se.",
                    Address = "Vrapčići b.b",
                    Phone = "+387 61 345 234",
                    OpeningTime = TimeSpan.Parse("07:00"),
                    ClosingTime = TimeSpan.Parse("23:00"),
                    AdminUserId = admin.Id,
                    RestaurantImage = LoadImageOrNull("restaurant.jpg")
                });
                await _db.SaveChangesAsync();
            }

            // ===== KATEGORIJE =====
            if (!await _db.Categories.AnyAsync())
            {
                await _db.Categories.AddRangeAsync(new[]
                {
                    new Category { CategoryName = "Janjetina" },
                    new Category { CategoryName = "Roštilj" },
                    new Category { CategoryName = "Tjestenine" },
                    new Category { CategoryName = "Pizze" },
                    new Category { CategoryName = "Salate" },
                    new Category { CategoryName = "Bezalkoholna pića" },
                });
                await _db.SaveChangesAsync();
            }

            // ===== ARTIKLI  =====
            if (!await _db.Articles.AnyAsync())
            {
                var cat = new Dictionary<string, int>();
                foreach (var c in await _db.Categories.ToListAsync()) cat[c.CategoryName] = c.CategoryId;

                var list = new List<Article>
                {
                    // Janjetina
                    A("Janjetina ispod sača",    24.90f, "Tradicionalna janjetina pečena ispod sača.", "roastedlamb.jpg", cat["Janjetina"]),
                    A("Peka od janjetine",       26.50f, "Janjetina i krompir pečeni u peki.",        "roastedlamb.jpg",      cat["Janjetina"]),
                    A("Janjetina na ražnju 1kg", 55.00f, "Porcija od 1kg janjetine s ražnja.",         "roastedlamb.jpg",    cat["Janjetina"]),
                    A("Janjetina kotleti",       22.50f, "Kotleti od janjetine sa roštilja.",         "roastedlamb.jpg",   cat["Janjetina"]),
                    A("Janjetina paprikaš",      17.90f, "Gulaš od janjetine sa povrćem.",            "roastedlamb.jpg",  cat["Janjetina"]),

                    // Roštilj
                    A("Ćevapi 10 kom",            9.00f, "Ćevapi sa lukom i somunom.",                "steak.jpg",      cat["Roštilj"]),
                    A("Pljeskavica",              8.50f, "Velika pljeskavica, prilog po izboru.",      "steak.jpg", cat["Roštilj"]),
                    A("Punjena pljeskavica",     10.50f, "Sa sirom i šunkom.",                         "steak.jpg",     cat["Roštilj"]),
                    A("Pileći ražnjići",         11.00f, "Piletina na ražnjićima sa povrćem.",         "steak.jpg",    cat["Roštilj"]),
                    A("Teleći kotleti",          15.90f, "Sočni teleći kotleti sa žara.",              "steak.jpg",      cat["Roštilj"]),
                    A("Kobasice sa roštilja",     9.90f, "Domaće kobasice, senf i somun.",             "sausages.jpg",    cat["Roštilj"]),

                    // Tjestenine
                    A("Spaghetti Bolognese",     12.00f, "Paradajz sos i mljeveno meso.",               "pasta.jpg",   cat["Tjestenine"]),
                    A("Penne Alfredo",           13.50f, "Kremasti Alfredo sos sa piletinom.",          "spaguetti.jpg",     cat["Tjestenine"]),
                    A("Tagliatelle Carbonara",   14.00f, "Slanina, vrhnje i parmezan.",                  "carbonara.jpg",   cat["Tjestenine"]),
                    A("Lasagne",                 15.00f, "Slojevita tjestenina sa bešamelom.",          "pasta.jpg",     cat["Tjestenine"]),
                    A("Fettuccine Pesto",        13.00f, "Pesto: bosiljak, pinjoli, parmezan.",         "spaguetti.jpg",       cat["Tjestenine"]),
                    A("Gnocchi četiri sira",     14.20f, "Njoke u krem sosu od sireva.",                 "carbonara.jpg",     cat["Tjestenine"]),

                    // Pizze
                    A("Pizza Margherita",        10.00f, "Paradajz, mocarela, bosiljak.",               "margherita.jpg",  cat["Pizze"]),
                    A("Pizza Capricciosa",       12.00f, "Šunka, gljive, masline, sir.",                 "margherita.jpg", cat["Pizze"]),
                    A("Pizza Quattro Formaggi",  13.50f, "Četiri vrste sira.",                           "margherita.jpg",       cat["Pizze"]),
                    A("Pizza Vesuvio",           12.50f, "Ljuta: kulen, feferoni.",                      "margherita.jpg",     cat["Pizze"]),
                    A("Pizza Funghi",            11.50f, "Gljive i sir.",                                "margherita.jpg",      cat["Pizze"]),
                    A("Pizza Diavola",           12.90f, "Začinjena salama, čili.",                      "margherita.jpg",     cat["Pizze"]),
                    A("Pizza Prosciutto",        13.20f, "Pršut, rukola, parmezan.",                     "margherita.jpg",  cat["Pizze"]),
                    A("Pizza Primavera",         12.30f, "Svježe povrće i sir.",                         "margherita.jpg",   cat["Pizze"]),
                    A("Pizza BBQ piletina",      13.90f, "BBQ sos, piletina, luk.",                      "margherita.jpg",         cat["Pizze"]),

                    // Salate
                    A("Šopska salata",           6.50f, "Svježa salata sa sirom.",                      "salad.jpg",      cat["Salate"]),
                    A("Cezar salata",            8.50f, "Piletina, parmezan, dresing i krutoni.",       "salad.jpg",       cat["Salate"]),
                    A("Grčka salata",            7.00f, "Paradajz, krastavac, feta, masline.",          "salad.jpg",       cat["Salate"]),
                    A("Caprese",                 7.50f, "Mocarela, paradajz, bosiljak.",                "salad.jpg",     cat["Salate"]),

                    // Bezalkoholna pića
                    A("Espresso",                2.50f, "Kratka kafa.",                                 "coffe.jpg",    cat["Bezalkoholna pića"]),
                    A("Macchiato",               2.80f, "Espresso s kapom mlijeka.",                    "coffe.jpg",   cat["Bezalkoholna pića"]),
                    A("Coca-Cola 0.33L",         2.80f, "Gazirano osvježenje.",                          "cola.jpg",        cat["Bezalkoholna pića"]),
                    A("Fanta 0.33L",             2.80f, "Naranča.",                                      "cola.jpg",       cat["Bezalkoholna pića"]),
                    A("Sok od narandže",         3.00f, "Cijeđena narandža.",                            "cola.jpg",      cat["Bezalkoholna pića"]),
                    A("Limunada",                3.00f, "Svježi limun, voda, led.",                      "cola.jpg",    cat["Bezalkoholna pića"]),
                    A("Mineralna voda 0.5L",     2.00f, "Prirodna mineralna voda.",                      "cola.jpg",        cat["Bezalkoholna pića"]),
                };

                await _db.Articles.AddRangeAsync(list);
                await _db.SaveChangesAsync();
            }

            // ===== REZERVACIJE + NOTIFIKACIJE  =====
            var userGuest = await _db.Users.FirstAsync(u => u.UserName == "guest");
            var userDesktop = await _db.Users.FirstAsync(u => u.UserName == "marko");
            var userMobile = await _db.Users.FirstAsync(u => u.UserName == "ivana");
            var lana = await _db.Users.FirstAsync(u => u.UserName == "lana");
            var amir = await _db.Users.FirstAsync(u => u.UserName == "amir");

            if (!await _db.Reservations.AnyAsync())
            {
                var reservations = new List<Reservation>
                {
                    R(userGuest.Id,   DateOnly.FromDateTime(DateTime.Today.AddDays(1)),  new TimeOnly(19, 30), 4, RES_STATUS_PENDING,   "Porodična večera",   1, "+387 61 111 222", "Sto uz prozor"),
                    R(userDesktop.Id, DateOnly.FromDateTime(DateTime.Today.AddDays(3)),  new TimeOnly(20, 00), 2, RES_STATUS_CONFIRMED, "Poslovni sastanak",  0, "+387 61 222 333", "Tiši dio sale"),
                    R(userMobile.Id,  DateOnly.FromDateTime(DateTime.Today.AddDays(2)),  new TimeOnly(18, 00), 6, RES_STATUS_REJECTED,  "Rođendan",           2, "+387 61 333 444", "Baloni"),
                    R(lana.Id,        DateOnly.FromDateTime(DateTime.Today.AddDays(5)),  new TimeOnly(17, 30), 3, RES_STATUS_PENDING,   "Prijatelji",         0, "+387 61 444 555", null),
                    R(amir.Id,        DateOnly.FromDateTime(DateTime.Today.AddDays(-1)), new TimeOnly(21, 15), 2, RES_STATUS_CONFIRMED, "Iznenađenje",        0, "+387 61 555 666", "Skrivena torta"),
                };

                await _db.Reservations.AddRangeAsync(reservations);
                await _db.SaveChangesAsync();

                // notifikacije
                var notifications = new List<Notification>
                {
                    N(userGuest.Id,   reservations[0].ReservationId, "Na čekanju."),
                    N(userDesktop.Id, reservations[1].ReservationId, "Potvrđena."),
                    N(userMobile.Id,  reservations[2].ReservationId, "Odbijena."),
                    N(lana.Id,        reservations[3].ReservationId, "Na čekanju."),
                    N(amir.Id,        reservations[4].ReservationId, "Potvrđena."),
                };
                await _db.Notifications.AddRangeAsync(notifications);
                await _db.SaveChangesAsync();
            }

            // ===== NARUDŽBE + STAVKE — zadnjih 10 mjeseci, 1–10 narudžbi/mjesec =====
            if (!await _db.Orders.AnyAsync())
            {
                var rng = new Random(42); // deterministički seed radi ponovljivosti
                var allUsers = await _db.Users.Where(u => new[] { "guest", "marko", "ivana", "lana", "amir", "desktop", "mobile", "jelena" }.Contains(u.UserName)).ToListAsync();
                var allArts = await _db.Articles.AsNoTracking().ToListAsync();
                string[] pay = new[] { "cash", "card" };

                // Helper da izbjegnemo dupli code
                Article PickArt() => allArts[rng.Next(allArts.Count)];
                User PickUser() => allUsers[rng.Next(allUsers.Count)];
                string PickPay() => pay[rng.Next(pay.Length)];

                DateTime UtcNow = DateTime.UtcNow;

                for (int monthOffset = 0; monthOffset < 10; monthOffset++)
                {
                    // ciljamo "kalendarski mjesec" unazad
                    var targetMonthStart = new DateTime(UtcNow.Year, UtcNow.Month, 1).AddMonths(-monthOffset);
                    var targetMonthEnd = targetMonthStart.AddMonths(1).AddTicks(-1);

                    int ordersThisMonth = rng.Next(1, 11); // 1..10

                    for (int k = 0; k < ordersThisMonth; k++)
                    {
                        // nasumičan datum unutar mjeseca
                        var span = targetMonthEnd - targetMonthStart;
                        var randomTime = targetMonthStart.AddSeconds(rng.Next((int)span.TotalSeconds));

                        var buyer = PickUser();
                        var order = new Order
                        {
                            UserId = buyer.Id,
                            OrderDate = randomTime,
                            PaymentMethod = PickPay(),
                            TotalAmount = 0m
                        };
                        _db.Add(order);
                        await _db.SaveChangesAsync(); // da dobijemo OrderId

                        // 1..5 stavki po narudžbi
                        int items = rng.Next(1, 6);
                        var taken = new HashSet<int>(); // da u narudžbi ne dupliramo isti ArticleId

                        for (int i = 0; i < items; i++)
                        {
                            var art = PickArt();
                            // preskoči ako već postoji isti art u ovoj narudžbi
                            if (!taken.Add(art.ArticleId))
                            {
                                i--; // pokušaj ponovo
                                continue;
                            }

                            int qty = rng.Next(1, 4); // 1..3 kom
                            var oi = new OrderItem
                            {
                                OrderId = order.OrderId,
                                ArticleId = art.ArticleId,
                                Quantity = qty,
                                UnitPrice = (decimal)art.ArticlePrice
                            };
                            _db.Add(oi);
                        }

                        await _db.SaveChangesAsync();

                        // izračun total-a nakon što su stavke upisane
                        order.TotalAmount = await _db.OrderItems
                            .Where(i => i.OrderId == order.OrderId)
                            .SumAsync(i => i.UnitPrice * i.Quantity);

                        await _db.SaveChangesAsync();
                    }
                }
            }
            // ===== REVIEW  =====
            if (!await _db.Reviews.AnyAsync())
            {
                var now = DateTime.UtcNow;
                var reviews = new List<Review>
                {
                    new Review { ReviewerUserId = userGuest.Id,   Rating = 5, Comment = "Janjetina top!",                      CreatedAt = now.AddDays(-2) },
                    new Review { ReviewerUserId = userDesktop.Id, Rating = 4, Comment = "Pizze odlične, brza usluga.",         CreatedAt = now.AddDays(-1) },
                    new Review { ReviewerUserId = userMobile.Id,  Rating = 3, Comment = "Ćevapi solidni, moglo toplije.",      CreatedAt = now.AddHours(-12) },
                    new Review { ReviewerUserId = lana.Id,        Rating = 5, Comment = "Lasagne savršene, preporuka!",        CreatedAt = now.AddHours(-8) },
                    new Review { ReviewerUserId = amir.Id,        Rating = 4, Comment = "Odlična atmosfera i roštilj.",        CreatedAt = now.AddHours(-3) },
                };
                await _db.Reviews.AddRangeAsync(reviews);
                await _db.SaveChangesAsync();
            }

            // ===== REPORT EXPORT =====
            if (!await _db.ReportExports.AnyAsync())
            {
                var admin = await _db.Users.FirstAsync(u => u.UserName == "admin");
                await _db.ReportExports.AddAsync(new ReportExport
                {
                    UserId = admin.Id,
                    From = DateTime.UtcNow.AddDays(-30),
                    To = DateTime.UtcNow,
                    TotalUsers = await _db.Users.CountAsync(),
                    TotalOrders = await _db.Orders.CountAsync(),
                    TotalRevenue = await _db.Orders.SumAsync(o => o.TotalAmount),
                    TopArticlesJson = "[]",
                    CreatedAt = DateTime.UtcNow,
                    PdfSizeBytes = 0,
                    PdfSha256 = null
                });
                await _db.SaveChangesAsync();
            }

            return Ok("Seed complete with rich sample data.");
        }

        // ===== Helper konstruktori =====

        private static User MakeUser(string username, string email, string first, string last, string rawPassword, PasswordHasher<User> hasher)
        {
            var u = new User
            {
                UserName = username,
                NormalizedUserName = username.ToUpperInvariant(),
                Email = email,
                NormalizedEmail = email.ToUpperInvariant(),
                EmailConfirmed = true,
                PhoneNumber = "+38761000000",
                PhoneNumberConfirmed = false,
                TwoFactorEnabled = false,
                LockoutEnabled = false,
                AccessFailedCount = 0,
                SecurityStamp = Guid.NewGuid().ToString("N"),
                ConcurrencyStamp = Guid.NewGuid().ToString("N"),
                FirstName = first,
                LastName = last,
                Created = DateTime.UtcNow
            };
            u.PasswordHash = hasher.HashPassword(u, rawPassword);
            return u;
        }

       

        private static Reservation R(int userId, DateOnly date, TimeOnly time, int guests, int status, string reason, int minors, string phone, string? special)
            => new Reservation
            {
                UserId = userId,
                ReservationDate = date,
                ReservationTime = time,
                NumberOfGuests = guests,
                ReservationStatus = status,
                ReservationReason = reason,
                NumberOfMinors = minors,
                ContactPhone = phone,
                SpeciaLRequests = special
            };


        private static Notification N(int userId, int reservationId, string msg) => new Notification
        {
            UserId = userId,
            ReservationId = reservationId,
            Message = msg
        };
        private byte[]? LoadImageOrNull(string fileName)
        {
            // 1) bin/.../wwwroot
            var p1 = Path.Combine(_webRoot, "pics", fileName);
            if (System.IO.File.Exists(p1)) return System.IO.File.ReadAllBytes(p1);

            // 2) projektni wwwroot (isti nivo kao Program.cs)
            var p2 = Path.Combine(_contentRoot, "wwwroot", "pics", fileName);
            if (System.IO.File.Exists(p2)) return System.IO.File.ReadAllBytes(p2);

            Console.WriteLine($"[Seed] Image not found: {fileName}\n  Tried:\n  - {p1}\n  - {p2}");
            return Array.Empty<byte>(); ;
        }

        private byte[] LoadImageOrEmpty(string fileName) =>
            LoadImageOrNull(fileName) ?? Array.Empty<byte>();

        private Article A(string name, float price, string desc, string img, int categoryId) => new Article
        {
            ArticleName = name,
            ArticlePrice = price,
            ArticleDescription = desc,
            ArticleImage = LoadImageOrNull(img),
            CategoryId = categoryId
        };
    }

}
