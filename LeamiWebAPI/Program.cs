using Leami.Services;
using Leami.Model;
using Leami.Services.Database;
using Microsoft.EntityFrameworkCore;
using Leami.Model.Entities;
using Microsoft.AspNetCore.Identity;
using MapsterMapper;
using Mapster;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.OpenApi.Models;



var builder = WebApplication.CreateBuilder(args);

builder.Services.AddScoped<IArticleService, ArticleService>();
builder.Services.AddScoped<IUserService, UserService>();



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

var connectionString = builder.Configuration.GetConnectionString("LeamiConnection") ?? throw new InvalidOperationException("Missing connection string 'LeamiConnection'");
builder.Services.AddDatabaseServices(connectionString);



builder.Services.AddMapster();

var app = builder.Build();

//using var scope = app.Services.CreateScope();
//var roleMgr = scope.ServiceProvider.GetRequiredService<RoleManager<Role>>();
//string[] roles = new[] { "Guest", "Employee", "Admin" };
//foreach (var roleName in roles)
//    if (!await roleMgr.RoleExistsAsync(roleName))
//        await roleMgr.CreateAsync(new Role { Name = roleName });


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
