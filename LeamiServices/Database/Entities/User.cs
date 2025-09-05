using System.ComponentModel.DataAnnotations;
using Leami.Services.Database.Entities;
using Microsoft.AspNetCore.Identity;    

namespace Leami.Model.Entities
{
    public class User : IdentityUser<int>
    {
        [MaxLength(50)] public string FirstName { get; set; } = string.Empty;
        [MaxLength(50)] public string LastName { get; set; } = string.Empty;
        public DateTime? Created { get; set; } = DateTime.UtcNow;
        public DateTime? LastLoginAt { get; set; }
        public byte[]? UserImage { get; set; }
        public EmployeeDetails? EmployeeDetails { get; set; }
        public AdministratorDetails? AdminDetails { get; set; }
        public GuestDetails? GuestDetails { get; set; }
       

        public RestaurantInfo? ManagedRestaurant { get; set; }
        public ICollection<Review>? Reviews { get; set; } = new List<Review>();
        public ICollection<IdentityUserRole<int>>? UserRoles { get; set; } = new List<IdentityUserRole<int>>();


    }

}

