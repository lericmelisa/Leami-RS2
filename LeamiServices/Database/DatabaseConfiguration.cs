using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.Database
{
    public static class DatabaseConfiguration
    {
        public static void AddDatabaseServices (this IServiceCollection services, string connectionString)
        {
            services.AddDbContext<LeamiDbContext>(options =>
                options.UseSqlServer(connectionString, sql => sql.MigrationsAssembly("Leami.Services")));
        }   
    }
}
