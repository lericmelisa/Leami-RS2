using Leami.Model.Entities;
using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.Database;
using Mapster;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using static System.Net.WebRequestMethods;
using static System.Runtime.InteropServices.JavaScript.JSType;


namespace Leami.Services
{
    public class UserService:BaseCRUDService<UserResponse, UserSearchObject, User,UserRegistrationRequest, UserUpdateRequest>,IUserService
    {

        private readonly UserManager<User> _userManager;
        private readonly RoleManager<Role> _roleManager;
        private readonly IMapper mapper;
        LeamiDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly IHttpContextAccessor _http;
        public UserService(LeamiDbContext leamiDbContext, IMapper _mapper, IConfiguration configuration, UserManager<User> userManager,RoleManager<Role> roleManager, IHttpContextAccessor http) :base(leamiDbContext, _mapper)
        {
            mapper = _mapper;
            _userManager = userManager;
            _roleManager = roleManager;
            _context = leamiDbContext;
            _configuration = configuration; 
            _http = http;   
        }
        protected override IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchObject search)
        {

            if (string.IsNullOrWhiteSpace(search.FTS) && string.IsNullOrWhiteSpace(search.RoleName))
                return query; // nema FTS → vrati sve

            if (!string.IsNullOrWhiteSpace(search.RoleName))
            {
                var role = search.RoleName.Trim();
                query = query.Where(u =>
                        _context.Set<IdentityUserRole<int>>().Any(ur =>
                            ur.UserId == u.Id &&
                            _context.Roles.Any(r => r.Id == ur.RoleId && r.Name!.Contains(role))
                        ));
                }


            if (search.FTS !=null)
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

            // Ako je cijeli req null (model-binding može poslati null), samo vrati trenutno stanje
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
                        Description = roleEntityNull.Description
                    };
                }
                dtoNull.JobTitle = user.EmployeeDetails?.JobTitle;
                dtoNull.HireDate = user.EmployeeDetails?.HireDate;
                dtoNull.Note = user.EmployeeDetails?.Note;
                return dtoNull;
            }
            // 1) Patch baznih polja — mijenjaj samo ako je vrijednost POSLANA i NIJE prazna
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

            // Ako se pošalje slika, ali je prazna (0 bajtova) – ne diraj
            if (req.UserImage != null && req.UserImage.Length > 0)
                user.UserImage = req.UserImage;

            // 2) Promjena lozinke — samo ako je POSLANA i NIJE prazna
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

                // osvježi set nakon promjena
                targetRoleNames = (await _userManager.GetRolesAsync(user))
                    .ToHashSet(StringComparer.OrdinalIgnoreCase);
            }
            else
            {
                // ne mijenjamo role
                targetRoleNames = currentRoleNames;
            }

            // 4) 1–1 *Details* — mijenjaj samo ako su polja poslata (null/prazno = ne diraj)
            await EnsureDetailsForRolesAsync(user, targetRoleNames, req);
            // (u EnsureDetailsForRolesAsync budi sigurna da radiš provjere: 
            //  if (req.JobTitle != null) ..., if (req.HireDate != null) ..., if (req.Note != null) ...)

            // 5) Sačuvaj
            await _context.SaveChangesAsync();

            // 6) Mapiraj iz AŽURIRANOG entiteta i dopuni Role/EmployeeDetails iz baze (ne iz req)
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
                    Description = roleEntity.Description
                };
            }
            else
            {
                dto.Role = null;
            }

            // EmployeeDetails flatten IZ BAZE (ostavi ako je req imao prazno/null)
            dto.JobTitle = user.EmployeeDetails?.JobTitle;
            dto.HireDate = user.EmployeeDetails?.HireDate;
            dto.Note = user.EmployeeDetails?.Note;

            return dto;
        
        }
        private async Task EnsureDetailsForRolesAsync(User user, HashSet<string> roleNames, UserUpdateRequest req)
        {
            // Employee
            if (roleNames.Contains("Employee"))
            {
                if (user.EmployeeDetails == null)
                {
                    // Kreiraj samo ako je došao bar neki podatak; ili koristi pametne default-e
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
        //protected override void MapToEntityUpdate(User entity, UserUpdateRequest req)
        //{
        //    // ---- bazna polja ----
        //    if (!string.IsNullOrWhiteSpace(req.FirstName))
        //        entity.FirstName = req.FirstName!.Trim();

        //    if (!string.IsNullOrWhiteSpace(req.LastName))
        //        entity.LastName = req.LastName!.Trim();

        //    if (!string.IsNullOrWhiteSpace(req.Email))
        //    {
        //        var email = req.Email!.Trim();
        //        entity.Email = email;
        //        entity.UserName = email;
        //        entity.NormalizedEmail = email.ToUpperInvariant();
        //        entity.NormalizedUserName = email.ToUpperInvariant();
        //    }

        //    if (req.UserImage != null && req.UserImage!.Length > 0)
        //        entity.UserImage = req.UserImage;

        //    // ---- employee polja samo ako je entitet stvarno Employee ----

        //        // Ako želiš dopustiti “pražnjenje” polja, koristi (req.JobTitle != null) umjesto !IsNullOrWhiteSpace
        //        if (!string.IsNullOrWhiteSpace(req.JobTitle))
        //            entity.JobTitle = req.JobTitle!;

        //        if (req.HireDate.HasValue)
        //        entity.HireDate = req.HireDate.Value;

        //        if (req.Note != null) // dopušta i prazni string da ‘počisti’ bilješku
        //        entity.Note = req.Note!;

        //    // RoleIds odrađuješ u BeforeUpdate (što već imaš).
        //}


        //protected override async Task BeforeUpdate(User entity, UserUpdateRequest request)
        //{
        //    // 1) Update password ako je promijenjen
        //    if (!string.IsNullOrWhiteSpace(request.Password))
        //    {
        //        var passwordHasher = new PasswordHasher<User>();
        //        entity.PasswordHash = passwordHasher.HashPassword(entity, request.Password);
        //    }

        //    // 2) Update rola
        //    if (request.RoleIds != null && request.RoleIds.Any())
        //    {
        //        // Nađi sve trenutne role za usera
        //        var currentRoles = _context.Set<UserRole>().Where(ur => ur.UserId == entity.Id);

        //        // Obrisi ih
        //        _context.Set<UserRole>().RemoveRange(currentRoles);

        //        // Dodaj nove
        //        foreach (var roleId in request.RoleIds)
        //        {
        //            var newUserRole = new UserRole
        //            {
        //                UserId = entity.Id,
        //                RoleId = roleId
        //            };
        //            await _context.Set<UserRole>().AddAsync(newUserRole);
        //        }
        //    }


        //}
        private bool CallerIsAdmin =>
      _http.HttpContext?.User?.IsInRole("Administrator") == true;
        public override async Task<UserResponse> CreateAsync(UserRegistrationRequest request)
        {
            if (await _userManager.FindByEmailAsync(request.Email) is not null) //implemenitrat USER EXCEPTION
                throw new InvalidOperationException("Korisnik s ovom email adresom već postoji.");


            // 2) Kreiraj novi Identity korisnika
            var user = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                Created = DateTime.Now,         
                LastLoginAt =DateTime.Now,
                UserName = request.Email,   
                UserImage=request.UserImage// <— ovdje automatski kopiraš e‑mail u Username
            };

            // 3) Kreiranje uz hash lozinke
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
            // 1) Dohvati korisnika po korisničkom imenu (ili e-mailu, kako god)
            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user is null)
                return null;

            // 2) Provjeri lozinku (Identity interno radi PBKDF2 hash+salt)
            if (!await _userManager.CheckPasswordAsync(user, request.Password))
                return null;


            // 3) Ažuriraj podatak o zadnjem loginu
            user.LastLoginAt = DateTime.UtcNow;
            await _userManager.UpdateAsync(user);


            
            // 4) Mapiraj osnovne podatke u response DTO
            var response = mapper.Map<UserResponse>(user);
            response.LastLoginAt = user.LastLoginAt;

            // 5) Učitaj role korisnika
            var roleNames = await _userManager.GetRolesAsync(user);

            // 6) Dohvati Role entitete da vidiš Id i Description
            var roleEntities = await _roleManager.Roles
                .Where(r => roleNames.Contains(r.Name))
                .ToListAsync();

            
           

            (response.Token, response.Expiration) = await GenerateJwtAsync(user);

            return response;

        }
        private async Task<(string Token, DateTime Expires)> GenerateJwtAsync(User user)
        {
            // 1) uloge
            var roleNames = await _userManager.GetRolesAsync(user);

            // 2) claimovi (Sub = subject = email; Jti = jedinstveni ID tokena)
            var authClaims = new List<Claim>
    {
        new Claim(JwtRegisteredClaimNames.Sub, user.Email ?? user.UserName ?? user.Id.ToString()),
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
        new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
        new Claim(ClaimTypes.Name, user.Email ?? user.UserName ?? string.Empty)
    };
            authClaims.AddRange(roleNames.Select(r => new Claim(ClaimTypes.Role, r)));

            // 3) parametri iz konfiguracije
            var issuer = _configuration["Jwt:Issuer"];
            var audience = _configuration["Jwt:Audience"];
            var keyBytes = Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!);
            var expireMinutes = double.Parse(_configuration["Jwt:ExpireMinutes"]!);

            var expires = DateTime.Now.AddMinutes(expireMinutes);

            // 4) potpis + token
            var creds = new SigningCredentials(new SymmetricSecurityKey(keyBytes), SecurityAlgorithms.HmacSha256);
            var jwt = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: authClaims,
                notBefore: DateTime.UtcNow,
                expires: expires,
                signingCredentials: creds
            );

            return (new JwtSecurityTokenHandler().WriteToken(jwt), jwt.ValidTo);
        }

        public override async Task<List<UserResponse>> GetAsync(UserSearchObject search)
        {
            var baseResult = await base.GetAsync(search);
            if (baseResult.Count == 0) return baseResult;

            var ids = baseResult.Select(x => x.Id).ToList();

            // dovuci korisnike sa EmployeeDetails
            var users = await _context.Users
                .Where(u => ids.Contains(u.Id))
                .Include(u => u.EmployeeDetails)
                .AsNoTracking()
                .ToListAsync();

            var userMap = users.ToDictionary(u => u.Id, u => u);

            // učitaj sve role jednom (3 komada kod tebe)
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
