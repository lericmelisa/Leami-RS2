using Leami.Model.Entities;
using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.Database;
using Leami.Services.Database.Entities;
using Leami.Services.Migrations;
using Leami.Services.Services;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;



namespace Leami.Services.IServices
{
    public class UserService : BaseCRUDService<UserResponse, UserSearchObject, User, UserRegistrationRequest, UserUpdateRequest>, IUserService
    {

        private readonly UserManager<User> _userManager;
        private readonly RoleManager<Role> _roleManager;
        private readonly IMapper mapper;
        LeamiDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly IHttpContextAccessor _http;
        public UserService(LeamiDbContext leamiDbContext, IMapper _mapper, IConfiguration configuration, UserManager<User> userManager, RoleManager<Role> roleManager, IHttpContextAccessor http) : base(leamiDbContext, _mapper)
        {
            mapper = _mapper;
            _userManager = userManager;
            _roleManager = roleManager;
            _context = leamiDbContext;
            _configuration = configuration;
            _http = http;
        }

        public async Task<ChangePasswordResponse> ChangePasswordAsync(ChangePasswordRequest req)
        {
            var user = await _userManager.FindByIdAsync(req.UserId.ToString())
                       ?? throw new KeyNotFoundException("Korisnik nije pronađen.");

            var principal = _http.HttpContext?.User;
            if (principal == null || !principal.Identity?.IsAuthenticated == true)
                throw new UnauthorizedAccessException("Niste prijavljeni.");

            if (string.IsNullOrWhiteSpace(req.OldPassword))
                throw new ArgumentException("Stara lozinka je obavezna.");

            var result = await _userManager.ChangePasswordAsync(user, req.OldPassword, req.NewPassword);
            if (!result.Succeeded)
                throw new InvalidOperationException(string.Join("; ", result.Errors.Select(e => e.Description)));

           await _userManager.UpdateSecurityStampAsync(user);

            user = await _userManager.FindByIdAsync(user.Id.ToString());

            var (token, exp) = await GenerateJwtAsync(user);

            return new ChangePasswordResponse
            {
                Token = token,
                Expiration = exp
            };
        }



        public override async Task<UserResponse> GetByIdAsync(int id)
        {
            var entity = await _context.Users
       .Include(u => u.UserRoles)
       .FirstOrDefaultAsync(u => u.Id == id);

            if (entity == null)
                return null;

            var roleNames = await _userManager.GetRolesAsync(entity);

            var roleDtos = await _roleManager.Roles
                   .Where(r => roleNames.Contains(r.Name))
                   .Select(r => new RolesResponse
                   {
                       Roleid = r.Id,
                       RoleName = r.Name!,
                       Description = r.Description
                   })
            .ToListAsync();

            var response = mapper.Map<UserResponse>(entity);
           
            response.Role = roleDtos.FirstOrDefault();

            return response;
        }
        protected override IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchObject search)
        {

            if (string.IsNullOrWhiteSpace(search.FTS) && string.IsNullOrWhiteSpace(search.RoleName))
                return query;

            if (!string.IsNullOrWhiteSpace(search.RoleName))
            {
                var role = search.RoleName.Trim();
                query = query.Where(u =>
                        _context.Set<IdentityUserRole<int>>().Any(ur =>
                            ur.UserId == u.Id &&
                            _context.Roles.Any(r => r.Id == ur.RoleId && r.Name!.Contains(role))
                        ));
            }


            if (search.FTS != null)
            {
                var fts = search.FTS.Trim();

                query = query.Where(u =>
                    u.Email.Contains(fts) ||
                    u.FirstName.Contains(fts) ||
                    u.LastName.Contains(fts) ||
                    _context.Set<IdentityUserRole<int>>().Any(ur =>
                        ur.UserId == u.Id &&
                        _context.Roles.Any(r => r.Id == ur.RoleId && r.Name!.Contains(fts)))
                );

                return query;
            }
            return query;
        }

        public override async Task<UserResponse> UpdateAsync(int id, UserUpdateRequest req)
        {
            var user = await _context.Users
                .Include(u => u.EmployeeDetails)
                .Include(u => u.AdminDetails)
                .Include(u => u.GuestDetails)
                .FirstOrDefaultAsync(u => u.Id == id);


            if (user is null)
                throw new KeyNotFoundException("User not found.");

            if (req == null)
            {
                var dtoNull = mapper.Map<UserResponse>(user);
                var rnNull = await _userManager.GetRolesAsync(user);
                var pickNull = rnNull.Contains("Administrator") ? "Administrator"
                            : rnNull.Contains("Employee") ? "Employee"
                            : rnNull.Contains("Guest") ? "Guest"
                            : rnNull.FirstOrDefault();

                if (pickNull != null)
                {
                    var roleEntityNull = await _roleManager.Roles.FirstOrDefaultAsync(r => r.Name == pickNull);
                    dtoNull.Role = roleEntityNull == null ? null : new RolesResponse
                    {
                        Roleid = roleEntityNull.Id,
                        RoleName = roleEntityNull.Name!,
                        Description = roleEntityNull.Description,
                        
                    };
                }
                dtoNull.JobTitle = user.EmployeeDetails?.JobTitle;
                dtoNull.HireDate = user.EmployeeDetails?.HireDate;
           

                dtoNull.Note = user.EmployeeDetails?.Note;
                return dtoNull;
            }
           
            if (!string.IsNullOrWhiteSpace(req.FirstName))
                user.FirstName = req.FirstName.Trim();

            if (!string.IsNullOrWhiteSpace(req.LastName))
                user.LastName = req.LastName.Trim();

            if (!string.IsNullOrWhiteSpace(req.Email))
            {
                var email = req.Email.Trim();
                if (!string.Equals(email, user.Email, StringComparison.OrdinalIgnoreCase))
                {
                    user.Email = email;
                    user.UserName = email; // strategija: UserName = Email
                    user.NormalizedEmail = email.ToUpperInvariant();
                    user.NormalizedUserName = email.ToUpperInvariant();
                }
            }

           
            user.UserImage = req.UserImage;
            // Promjena lozinke — samo ako je POSLANA i NIJE prazna
            if (!string.IsNullOrWhiteSpace(req.Password))
            {
                var hasPassword = await _userManager.HasPasswordAsync(user);
                IdentityResult pwdRes;
                if (hasPassword)
                {
                    var rem = await _userManager.RemovePasswordAsync(user);
                    if (!rem.Succeeded)
                        throw new InvalidOperationException("Remove password failed: " + string.Join("; ", rem.Errors.Select(e => e.Description)));
                    pwdRes = await _userManager.AddPasswordAsync(user, req.Password);
                }
                else
                {
                    pwdRes = await _userManager.AddPasswordAsync(user, req.Password);
                }
                if (!pwdRes.Succeeded)
                    throw new InvalidOperationException("Set password failed: " + string.Join("; ", pwdRes.Errors.Select(e => e.Description)));
            }

            // 3) ROLE SYNC — mijenjaj role SAMO ako RoleIds ima vrijednosti; ako je null ili prazno, NE diraj role
            var currentRoleNames = (await _userManager.GetRolesAsync(user))
                .ToHashSet(StringComparer.OrdinalIgnoreCase);

            HashSet<string> targetRoleNames;
            if (req.RoleIds != null && req.RoleIds.Count > 0)
            {
                var distinctIds = req.RoleIds.Distinct().ToList();
                var roles = await _context.Roles.Where(r => distinctIds.Contains(r.Id)).ToListAsync();
                if (roles.Count != distinctIds.Count)
                    throw new ArgumentException("Jedna ili više rola ne postoji.");

                targetRoleNames = roles.Select(r => r.Name!)
                                       .ToHashSet(StringComparer.OrdinalIgnoreCase);

                var toAdd = targetRoleNames.Except(currentRoleNames).ToArray();
                var toRem = currentRoleNames.Except(targetRoleNames).ToArray();

                if (toAdd.Length > 0)
                {
                    var addRes = await _userManager.AddToRolesAsync(user, toAdd);
                    if (!addRes.Succeeded)
                        throw new InvalidOperationException("Add roles failed: " + string.Join("; ", addRes.Errors.Select(e => e.Description)));
                }
                if (toRem.Length > 0)
                {
                    var remRes = await _userManager.RemoveFromRolesAsync(user, toRem);
                    if (!remRes.Succeeded)
                        throw new InvalidOperationException("Remove roles failed: " + string.Join("; ", remRes.Errors.Select(e => e.Description)));
                }

               
                targetRoleNames = (await _userManager.GetRolesAsync(user))
                    .ToHashSet(StringComparer.OrdinalIgnoreCase);
            }
            else
            {
                // ne mijenjamo role
                targetRoleNames = currentRoleNames;
            }
         
                        
             await _userManager.SetPhoneNumberAsync(user, req.PhoneNumber.Trim()?? " ");
         


            
            await EnsureDetailsForRolesAsync(user, targetRoleNames, req);
            

            
            await _context.SaveChangesAsync();

           
            var dto = mapper.Map<UserResponse>(user);

            var roleNames = await _userManager.GetRolesAsync(user);
            string? pick = roleNames.Contains("Administrator") ? "Administrator"
                       : roleNames.Contains("Employee") ? "Employee"
                       : roleNames.Contains("Guest") ? "Guest"
                       : roleNames.FirstOrDefault();

            if (pick != null)
            {
                var roleEntity = await _roleManager.Roles.FirstOrDefaultAsync(r => r.Name == pick);
                dto.Role = roleEntity == null ? null : new RolesResponse
                {
                    Roleid = roleEntity.Id,
                    RoleName = roleEntity.Name!,
                    Description = roleEntity?.Description
                };
            }
            else
            {
                dto.Role = null;
            }

            
            dto.JobTitle = user.EmployeeDetails?.JobTitle;
            dto.HireDate = user.EmployeeDetails?.HireDate;
            dto.Note = user.EmployeeDetails?.Note;

            (dto.Token, dto.Expiration) = await GenerateJwtAsync(user);
            return dto;


        }
        private async Task EnsureDetailsForRolesAsync(User user, HashSet<string> roleNames, UserUpdateRequest req)
        {
            if (roleNames.Contains("Employee"))
            {
                if (user.EmployeeDetails == null)
                {
                    if (req.JobTitle != null || req.HireDate != null || req.Note != null)
                    {
                        user.EmployeeDetails = new EmployeeDetails
                        {
                            UserId = user.Id,
                            JobTitle = req.JobTitle ?? "Employee",
                            HireDate = req.HireDate ?? DateTime.UtcNow,
                            Note = req.Note ?? ""
                        };
                        _context.EmployeeDetails.Add(user.EmployeeDetails);
                    }
                    // Ako NEMA podataka za EmployeeDetails, ostavi da se kasnije doda kroz poseban update.
                }
                else
                {
                    if (req.JobTitle != null) user.EmployeeDetails.JobTitle = req.JobTitle;
                    if (req.HireDate != null) user.EmployeeDetails.HireDate = req.HireDate.Value;
                    if (req.Note != null) user.EmployeeDetails.Note = req.Note;
                    _context.EmployeeDetails.Update(user.EmployeeDetails);
                }
            }
            else
            {
                if (user.EmployeeDetails != null)
                {
                    _context.EmployeeDetails.Remove(user.EmployeeDetails);
                    user.EmployeeDetails = null;
                }
            }

            // Administrator
            if (roleNames.Contains("Administrator"))
            {
                if (user.AdminDetails == null)
                {
                    user.AdminDetails = new AdministratorDetails { UserId = user.Id };
                    _context.AdminDetails.Add(user.AdminDetails);
                }
            }
            else
            {
                if (user.AdminDetails != null)
                {
                    _context.AdminDetails.Remove(user.AdminDetails);
                    user.AdminDetails = null;
                }
            }

            // Guest
            if (roleNames.Contains("Guest"))
            {
                if (user.GuestDetails == null)
                {
                    user.GuestDetails = new GuestDetails { UserId = user.Id };
                    _context.GuestDetails.Add(user.GuestDetails);
                }
            }
            else
            {
                if (user.GuestDetails != null)
                {
                    _context.GuestDetails.Remove(user.GuestDetails);
                    user.GuestDetails = null;
                }
            }

            await Task.CompletedTask;
        }
      
        private bool CallerIsAdmin =>
      _http.HttpContext?.User?.IsInRole("Administrator") == true;
        public override async Task<UserResponse> CreateAsync(UserRegistrationRequest request)
        {
            if (await _userManager.FindByEmailAsync(request.Email) is not null) 
                throw new InvalidOperationException("Korisnik s ovom email adresom već postoji.");


       
            var user = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                Created = DateTime.Now,
                LastLoginAt = DateTime.Now,
                UserName = request.Email,
                UserImage = request.UserImage
            };

         
            var createResult = await _userManager.CreateAsync(user, request.Password);
            if (!createResult.Succeeded)
                throw new InvalidOperationException(
                    string.Join("; ", createResult.Errors.Select(e => e.Description))
                );

            // 3) Dodjela rola: kontrolisana!
            if (!CallerIsAdmin)
            {
                // javna registracija → uvijek Guest
                var addGuest = await _userManager.AddToRoleAsync(user, "Guest");
                if (!addGuest.Succeeded)
                    throw new InvalidOperationException("Dodavanje uloge 'Guest' nije uspjelo: " +
                        string.Join("; ", addGuest.Errors.Select(e => e.Description)));
            }
            else
            {
                // admin smije slati RoleIds; ako ništa nije poslano → npr. Employee kao default
                var targetRoleIds = request.RoleIds?.Distinct().ToList() ?? new List<int>();
                var rolesToAssign = targetRoleIds.Count > 0
                    ? await _roleManager.Roles.Where(r => targetRoleIds.Contains(r.Id)).ToListAsync()
                    : new List<Role> { await _roleManager.FindByNameAsync("Employee")! };

                if (rolesToAssign.Any(r => r == null))
                    throw new InvalidOperationException("Tražena rola ne postoji.");

                foreach (var role in rolesToAssign)
                {
                    var addRole = await _userManager.AddToRoleAsync(user, role.Name!);
                    if (!addRole.Succeeded)
                        throw new InvalidOperationException($"Dodavanje role '{role.Name}' nije uspjelo: " +
                            string.Join("; ", addRole.Errors.Select(e => e.Description)));
                }
            }

            var response = mapper.Map<UserResponse>(user);


            var roleNames = await _userManager.GetRolesAsync(user);
            var roleEntities = await _roleManager.Roles
                .Where(r => roleNames.Contains(r.Name))
                .ToListAsync();



            (response.Token, response.Expiration) = await GenerateJwtAsync(user);

            return response;
        }
        public async Task<UserResponse?> LoginAsync(UserLoginRequest request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user is null) return null;

            var employee = await _context.Users
      .Include(u => u.EmployeeDetails)
      .FirstOrDefaultAsync(u => u.Id == user.Id);

            var valid = await _userManager.CheckPasswordAsync(user, request.Password);
            if (!valid) return null;


            user.LastLoginAt = DateTime.UtcNow;
            await _userManager.UpdateAsync(user);

            var roleNames = await _userManager.GetRolesAsync(user);

            var roleDtos = await _roleManager.Roles
                   .Where(r => roleNames.Contains(r.Name))
                   .Select(r => new RolesResponse
                   {
                       Roleid = r.Id,
                       RoleName = r.Name!,
                       Description = r.Description
                   })
                   .ToListAsync();

            var response = mapper.Map<UserResponse>(user);
            response.LastLoginAt = user.LastLoginAt;
            if (employee.EmployeeDetails != null)
            {
                response.JobTitle = employee.EmployeeDetails.JobTitle ?? " ";
                response.HireDate = employee.EmployeeDetails.HireDate;
                response.Note = employee.EmployeeDetails.Note ?? " ";
            }


            response.Role = roleDtos.FirstOrDefault();

            (response.Token, response.Expiration) = await GenerateJwtAsync(user);
            return response;

        }
        private async Task<(string Token, DateTime Expires)> GenerateJwtAsync(User user)
        {
            var roleNames = await _userManager.GetRolesAsync(user);
            var securityStamp = user.SecurityStamp ?? string.Empty;

            var claims = new List<Claim>
    {
        new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
        new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),   
        new Claim(ClaimTypes.Email, user.Email ?? string.Empty),   
        new Claim("uid", user.Id.ToString()),
        new Claim("sstamp", securityStamp)
    };
            claims.AddRange(roleNames.Select(r => new Claim(ClaimTypes.Role, r)));

            var issuer = _configuration["Jwt:Issuer"];
            var audience = _configuration["Jwt:Audience"];
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            var expires = DateTime.UtcNow.AddMinutes(double.Parse(_configuration["Jwt:ExpireMinutes"]!));

            var jwt = new JwtSecurityToken(issuer, audience, claims, DateTime.UtcNow, expires, creds);
            return (new JwtSecurityTokenHandler().WriteToken(jwt), jwt.ValidTo);
        }
        public async Task LogoutAsync()
        {
            var userIdStr = _http.HttpContext?.User?.FindFirstValue(ClaimTypes.NameIdentifier)
                          ?? _http.HttpContext?.User?.FindFirstValue("uid");

            if (!int.TryParse(userIdStr, out var userId)) return;

            var user = await _userManager.FindByIdAsync(userId.ToString());
            if (user == null) return;

            await _userManager.UpdateSecurityStampAsync(user); 
        }
        public override async Task<List<UserResponse>> GetAsync(UserSearchObject search)
        {
            var baseResult = await base.GetAsync(search);
            if (baseResult.Count == 0) return baseResult;

            var ids = baseResult.Select(x => x.Id).ToList();

          
            var users = await _context.Users
                .Where(u => ids.Contains(u.Id))
                .Include(u => u.EmployeeDetails)
                .AsNoTracking()
                .ToListAsync();

            var userMap = users.ToDictionary(u => u.Id, u => u);

            var allRoles = await _roleManager.Roles.AsNoTracking().ToListAsync();
            var roleByName = allRoles.ToDictionary(r => r.Name!, r => r, StringComparer.OrdinalIgnoreCase);

            foreach (var dto in baseResult)
            {
                var u = userMap[dto.Id];

                // EmployeeDetails flatten
                dto.JobTitle = u.EmployeeDetails?.JobTitle;
                dto.HireDate = u.EmployeeDetails?.HireDate;
                dto.Note = u.EmployeeDetails?.Note;

                // role preko Identity API
                var roleNames = await _userManager.GetRolesAsync(u);

                // odaberi prioritetnu
                string? pick = roleNames.Contains("Administrator") ? "Administrator"
                             : roleNames.Contains("Employee") ? "Employee"
                             : roleNames.Contains("Guest") ? "Guest"
                             : roleNames.FirstOrDefault();

                if (pick != null && roleByName.TryGetValue(pick, out var r))
                {
                    dto.Role = new RolesResponse
                    {
                        Roleid = r.Id,
                        RoleName = r.Name,
                        Description = r.Description
                    };
                }
                else
                {
                    dto.Role = null;
                }
            }

            return baseResult;
        }

    }
}
