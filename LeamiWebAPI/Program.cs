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
using LeamiWebAPI.Controllers;
using Microsoft.Data.SqlClient;



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


var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? throw new InvalidOperationException("Missing connection string 'LeamiConnection'");
builder.Services.AddDatabaseServices(connectionString);

builder.Services.AddIdentity<User, Role>(options =>
{
    // USER
    options.User.RequireUniqueEmail = true;

    // PASSWORD POLICY
    options.Password.RequiredLength = 8;        
    options.Password.RequireDigit = true;        
    options.Password.RequireLowercase = true;     
    options.Password.RequireUppercase = true;    
    options.Password.RequireNonAlphanumeric = false; 
    options.Password.RequiredUniqueChars = 1;     

}).AddEntityFrameworkStores<LeamiDbContext>().AddDefaultTokenProviders();

builder.Services.AddHttpContextAccessor();

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


try
{
    using var scope = app.Services.CreateScope();
    var context = scope.ServiceProvider.GetRequiredService<LeamiDbContext>();
    var env = scope.ServiceProvider.GetRequiredService<IWebHostEnvironment>();

    Console.WriteLine("Applying EF Core migrations (if any)...");
    try
    {
        await context.Database.MigrateAsync();
    }
    catch (SqlException ex) when (ex.Number == 1801) // Database already exists
    {
        // Ignorišemo – DB već postoji
        Console.WriteLine("Database already exists. Continuing without creating.");
    }

    // Idempotentni seed
    if (!await context.Users.AnyAsync())
    {
        Console.WriteLine("Database is empty. Starting data seeding...");
        var seeder = new SeedController(context, env);
        await seeder.Init();
        Console.WriteLine("Data seeding completed successfully.");
    }
    else
    {
        Console.WriteLine("Database already contains data. Skipping seeding.");
    }
}
catch (Exception ex)
{
    Console.WriteLine($"Startup DB step failed (non-fatal): {ex.Message}");
 
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();


