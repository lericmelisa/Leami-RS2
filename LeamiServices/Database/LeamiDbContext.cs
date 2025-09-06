using Leami.Model.Entities;
using Leami.Services.Database.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.Database
{
   public class LeamiDbContext : IdentityDbContext<User, Role, int>
{
    public LeamiDbContext(DbContextOptions<LeamiDbContext> options) : base(options) { }

      

        protected override void OnModelCreating(ModelBuilder b)
        {
            base.OnModelCreating(b);
            b.Entity<User>().ToTable("Users");
            b.Entity<Role>().ToTable("Roles");
            b.Entity<IdentityUserRole<int>>().ToTable("UserRoles");
            b.Entity<IdentityUserClaim<int>>().ToTable("UserClaims");
            b.Entity<IdentityUserLogin<int>>().ToTable("UserLogins");
            b.Entity<IdentityRoleClaim<int>>().ToTable("RoleClaims");
            b.Entity<IdentityUserToken<int>>().ToTable("UserTokens");



            b.Entity<EmployeeDetails>().ToTable("EmployeeDetails").HasKey(x => x.UserId);
            b.Entity<EmployeeDetails>()
                .HasOne(d => d.User).WithOne(u => u.EmployeeDetails)
                .HasForeignKey<EmployeeDetails>(d => d.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            b.Entity<AdministratorDetails>().ToTable("AdminDetails").HasKey(x => x.UserId);
            b.Entity<AdministratorDetails>()
                .HasOne(d => d.User).WithOne(u => u.AdminDetails)
                .HasForeignKey<AdministratorDetails>(d => d.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            b.Entity<GuestDetails>().ToTable("GuestDetails").HasKey(x => x.UserId);
            b.Entity<GuestDetails>()
                .HasOne(d => d.User).WithOne(u => u.GuestDetails)
                .HasForeignKey<GuestDetails>(d => d.UserId)
                .OnDelete(DeleteBehavior.Cascade);


           
            b.Entity<Article>()
                .HasOne(a => a.Category)
                .WithMany(c => c.Articles)
                .OnDelete(DeleteBehavior.Restrict);

           
            b.Entity<Review>()
                .HasOne(r => r.ReviewerUser)
                .WithMany(u => u.Reviews)
                .HasForeignKey(r => r.ReviewerUserId)
                .OnDelete(DeleteBehavior.Cascade);


            b.Entity<Notification>()
                 .HasOne(n => n.Reservation)
                 .WithMany(r => r.Notifications)
                 .HasForeignKey(n => n.ReservationId)
                 .OnDelete(DeleteBehavior.Cascade);

            b.Entity<Notification>()
                .HasOne(n => n.User)
                .WithMany(u => u.Notifications)
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.NoAction);



            b.Entity<RestaurantInfo>()
                .HasOne(ri => ri.Admin)
                .WithOne(u => u.ManagedRestaurant)
                .HasForeignKey<RestaurantInfo>(ri => ri.AdminUserId)
                .OnDelete(DeleteBehavior.Restrict);

            b.Entity<ReportExport>(e =>
            {
                e.HasOne(x => x.User)
                 .WithMany()
                 .HasForeignKey(x => x.UserId)
                 .OnDelete(DeleteBehavior.SetNull);

                e.Property(x => x.TopArticlesJson)
                 .HasColumnType("nvarchar(max)");
            });

            b.Entity<Order>().Property(x => x.TotalAmount).HasPrecision(18, 2);
            b.Entity<OrderItem>().Property(x => x.UnitPrice).HasPrecision(18, 2);
            b.Entity<ReportExport>().Property(x => x.TotalRevenue).HasPrecision(18, 2);
        }

        public DbSet<Article>? Articles { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<EmployeeDetails> EmployeeDetails { get; set; }
        public DbSet<AdministratorDetails> AdminDetails { get; set; }
        public DbSet<GuestDetails> GuestDetails { get; set; }
        public DbSet<Reservation> Reservations { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<RestaurantInfo> RestaurantInfos { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<ReportExport> ReportExports { get; set; }








    }
}
