using Leami.Model.Entities;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.Database
{
    public class LeamiDbContext: IdentityDbContext<User, Role, int> 
    {
        public LeamiDbContext(DbContextOptions<LeamiDbContext> options) : base(options)
        {
        }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<User>(b =>
            {
                b.ToTable("Users");                      
                b.HasDiscriminator<string>("UserType")   
                 .HasValue<User>("User")                 
                 .HasValue<Guest>("Guest")
                 .HasValue<Employee>("Employee")
                 .HasValue<Administrator>("Admin");
            });
        }
        // Defining DbSet properties for entities
        public DbSet<City>? Cities { get; set; }
        public DbSet<Article>? Articles { get; set; } 

    }
}
