using Leami.Services.Database;
using Leami.Services.Database.Entities;
using Microsoft.EntityFrameworkCore;
using Leami.Model.Entities;
using Microsoft.AspNetCore.Identity;
using Mapster;
using MapsterMapper;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.OpenApi.Models;
using Leami.Services.Services;
using Leami.Services.IServices;
using Stripe;
using RabbitMQ.Client;
using DotNetEnv;
using QuestPDF;
using QuestPDF.Infrastructure;
using System.Security.Claims;



var builder = WebApplication.CreateBuilder(args);
var contentRoot = builder.Environment.ContentRootPath;

var candidates = new[]
{
    Path.Combine(contentRoot, ".env"),
    Path.GetFullPath(Path.Combine(contentRoot, "..", ".env")),
    Path.GetFullPath(Path.Combine(contentRoot, "..", "..", ".env")),
};

var envFile = candidates.FirstOrDefault(System.IO.File.Exists);
if (envFile != null)
{
    DotNetEnv.Env.Load(envFile); // učita u process env
}


builder.Configuration
       .SetBasePath(Directory.GetCurrentDirectory())
       .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
       .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true)
       .AddEnvironmentVariables();  // .env varijable su sada u OS env


// Register StripeService
var stripeSecret =
    builder.Configuration["Stripe:SecretKey"]
    ?? Environment.GetEnvironmentVariable("Stripe__SecretKey")
    ?? throw new InvalidOperationException("Missing Stripe:SecretKey");

StripeConfiguration.ApiKey = stripeSecret;
builder.Services.AddScoped<StripeService>();
builder.Logging.AddConsole();


// registracija Mapstera
QuestPDF.Settings.License = LicenseType.Community;

builder.Services.AddSingleton(TypeAdapterConfig.GlobalSettings);
builder.Services.AddScoped<IMapper, ServiceMapper>();

builder.Services.AddSingleton<IRabbitMQService, RabbitMQConnectionManager>();

builder.Services.AddTransient<IReservationService, ReservationService>();

builder.Services.AddScoped<IArticleService, ArticleService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IRoleService, RoleService>();
builder.Services.AddScoped<IReviewService, ReviewLService>();
builder.Services.AddScoped<IRestaurantInfo, RestaurantInfoService>();
builder.Services.AddScoped<IOrderLService, OrderLService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IReportService, ReportService>();





var connectionString = builder.Configuration.GetConnectionString("LeamiConnection") ?? throw new InvalidOperationException("Missing connection string 'LeamiConnection'");
builder.Services.AddDatabaseServices(connectionString);




builder.Services.AddIdentity<User, Role>(options =>
{
    // USER
    options.User.RequireUniqueEmail = true;

    // PASSWORD POLICY
    options.Password.RequiredLength = 8;          // min dužina
    options.Password.RequireDigit = true;         // mora imati broj
    options.Password.RequireLowercase = true;     // malo slovo
    options.Password.RequireUppercase = true;     // veliko slovo
    options.Password.RequireNonAlphanumeric = false; //  spec. znak false
    options.Password.RequiredUniqueChars = 1;     // različitih znakova

}).AddEntityFrameworkStores<LeamiDbContext>().AddDefaultTokenProviders();

builder.Services.AddHttpContextAccessor();

// Add services to the container.var

var jwt = builder.Configuration.GetSection("Jwt");
var jwtKey = jwt["Key"];
var jwtIssuer = jwt["Issuer"];
var jwtAudience = jwt["Audience"];
var jwtExpire = int.Parse(jwt["ExpireMinutes"] ?? "60");


builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(
                                     Encoding.UTF8.GetBytes(jwtKey)),
        ClockSkew = TimeSpan.FromSeconds(30)
    };
    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = async ctx =>
        {
            var userManager = ctx.HttpContext.RequestServices.GetRequiredService<UserManager<User>>();

            var userId = ctx.Principal?.FindFirstValue(ClaimTypes.NameIdentifier);
            var tokenStamp = ctx.Principal?.FindFirst("sstamp")?.Value;

            if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(tokenStamp))
            {
                ctx.Fail("Missing user id or security stamp.");
                return;
            }

            var user = await userManager.FindByIdAsync(userId);
            if (user == null)
            {
                ctx.Fail("User not found.");
                return;
            }

            if (!string.Equals(user.SecurityStamp, tokenStamp, StringComparison.Ordinal))
            {
                ctx.Fail("Token revoked.");
            }
        }
    };
});


builder.Services.AddAuthorization();
builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();




builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Leami API", Version = "v1" });

    // 1) Definicija Bearer scheme
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        Description = "Unesi JWT token u formatu: Bearer {token}"
    });

    // 2) Obavezan security requirement za sve (ili samo za neke) endpoint-e
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme {
                Reference = new OpenApiReference {
                    Type = ReferenceType.SecurityScheme,
                    Id   = "Bearer"
                }
            },
            new string[] { } // nema specifičnih scope-ova za JWT
        }
    });
});






var app = builder.Build();


static string Mask(string? s)
    => string.IsNullOrEmpty(s) || s.Length < 8 ? "****" : $"{s[..4]}...{s[^4..]}";

if (app.Environment.IsDevelopment())
{
    app.Logger.LogInformation("Stripe key loaded: {Key}", Mask(stripeSecret));
}



await using (var scope = app.Services.CreateAsyncScope())
{
    await Seeder.RunAsync(scope.ServiceProvider, app.Configuration);
}


// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}



app.UseAuthentication();
app.UseAuthorization();


app.MapControllers();

app.Run();


static class Seeder
{
    public static async Task RunAsync(IServiceProvider services, IConfiguration config)
    {
        var db = services.GetRequiredService<LeamiDbContext>();
        var roleMgr = services.GetRequiredService<RoleManager<Role>>();
        var userMgr = services.GetRequiredService<UserManager<User>>();

        // 1) Migrate DB
        await db.Database.MigrateAsync();

        // 2) Roles
        string[] roles = { "Administrator", "Employee", "Guest" };
        foreach (var name in roles)
        {
            if (!await roleMgr.RoleExistsAsync(name))
            {
                var res = await roleMgr.CreateAsync(new Role
                {
                    Name = name,
                    NormalizedName = name.ToUpper(),
                    Description = null
                });
                if (!res.Succeeded)
                    throw new Exception("Role create failed: " + string.Join(", ", res.Errors.Select(e => e.Description)));
            }
        }

        // 3) Admin user (čita iz appsettings ako postoji; ima fallback)
        var adminEmail = config["Seed:AdminEmail"] ?? "admin@leami.local";
        var adminPass = config["Seed:AdminPassword"] ?? "StrongPass!123"; // promijeni u prod

        var admin = await userMgr.FindByEmailAsync(adminEmail);
        if (admin is null)
        {
            admin = new User
            {
                UserName = adminEmail,
                Email = adminEmail,
                EmailConfirmed = true,
                FirstName = "Admin",
                LastName = "User",
                Created = DateTime.UtcNow
            };

            var create = await userMgr.CreateAsync(admin, adminPass);
            if (!create.Succeeded)
                throw new Exception("Admin create failed: " + string.Join(", ", create.Errors.Select(e => e.Description)));
        }

        if (!await userMgr.IsInRoleAsync(admin, "Administrator"))
            await userMgr.AddToRoleAsync(admin, "Administrator");

        // 4) (opciono) upiši 1–1 AdminDetails za admina
        if (await db.AdminDetails.FindAsync(admin.Id) is null)
        {
            db.AdminDetails.Add(new AdministratorDetails { UserId = admin.Id });
            await db.SaveChangesAsync();
        }
    }
}