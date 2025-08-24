using Leami.Model;
using Leami.Services.Database;
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
using LeamiWebAPI.Controllers;



var builder = WebApplication.CreateBuilder(args);


// registracija Mapstera
builder.Services.AddSingleton(TypeAdapterConfig.GlobalSettings);
builder.Services.AddScoped<IMapper, ServiceMapper>();




builder.Services.AddScoped<IArticleService, ArticleService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IRoleService, RoleService>();
builder.Services.AddScoped<IReservationService, ReservationService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<IRestaurantInfo, RestaurantInfoService>();





var connectionString = builder.Configuration.GetConnectionString("LeamiConnection") ?? throw new InvalidOperationException("Missing connection string 'LeamiConnection'");
builder.Services.AddDatabaseServices(connectionString);





builder.Services.AddIdentity<User, Role>(options =>
{
    options.User.RequireUniqueEmail = true;
    //setovanje pravila
}).AddEntityFrameworkStores<LeamiDbContext>().AddDefaultTokenProviders();



// Add services to the container.var

var jwtSection = builder.Configuration.GetSection("Jwt");
var jwtIssuer = jwtSection.GetValue<string>("Issuer")
                   ?? throw new InvalidOperationException("Missing Jwt:Issuer");
var jwtAudience = jwtSection.GetValue<string>("Audience")
                   ?? throw new InvalidOperationException("Missing Jwt:Audience");
var jwtKey = jwtSection.GetValue<string>("Key")
                   ?? throw new InvalidOperationException("Missing Jwt:Key");
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
                                     Encoding.UTF8.GetBytes(jwtKey))
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

app.UseHttpsRedirection();

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