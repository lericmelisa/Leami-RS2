using Leami.Model.Entities;
using Leami.Model.Requests;

using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.Database;
using MapsterMapper;
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

namespace Leami.Services
{
    public class UserService:BaseCRUDService<UserResponse, UserSearchObject, User,UserRegistrationRequest, UserRegistrationRequest>,IUserService
    {

        private readonly UserManager<User> _userManager;
        private readonly RoleManager<Role> _roleManager;
        private readonly IMapper mapper;
        LeamiDbContext _context;
        private readonly IConfiguration _configuration;
        public UserService(LeamiDbContext leamiDbContext, IMapper _mapper, IConfiguration configuration, UserManager<User> userManager,RoleManager<Role> roleManager) :base(leamiDbContext, _mapper)
        {
            mapper = _mapper;
            _userManager = userManager;
            _roleManager = roleManager;
            _context = leamiDbContext;
            _configuration = configuration; 
        }
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
                Created = DateTime.UtcNow,         
                LastLoginAt =DateTime.Now,
                UserName = request.Email,    // <— ovdje automatski kopiraš e‑mail u Username
            };

            // 3) Kreiranje uz hash lozinke
            var createResult = await _userManager.CreateAsync(user, request.Password);
            if (!createResult.Succeeded)
                throw new InvalidOperationException(
                    string.Join("; ", createResult.Errors.Select(e => e.Description))
                );

            //4) Dodjela rola(ako su specificirane)

            if (request.RoleIds?.Any() == true)
            {
                foreach (var roleId in request.RoleIds)
                {
                    // pronađi rolu po ID-u
                    var role = await _roleManager.FindByIdAsync(roleId.ToString());
                    if (role != null)
                    {
                        var addRoleResult = await _userManager.AddToRoleAsync(user,role.Name);
                        if (!addRoleResult.Succeeded)
                            throw new InvalidOperationException(
                                $"Dodavanje role '{role.Name}' nije uspjelo: " +
                                string.Join("; ", addRoleResult.Errors.Select(e => e.Description))
                            );
                    }
                    else
                    {
                        throw new InvalidOperationException($"Rola s ID {roleId} ne postoji.");
                    }
                }
            }
            else
            {
                // ako ne želiš default rolu, možeš preskočiti; inače, npr.:
                // await _userManager.AddToRoleAsync(user, "User");
            }



            // 5) Mapiraj na DTO i vrati
            // (ili, ako želiš i role u responseu, pozovi svoj GetUserResponseWithRolesAsync)
            // 6) Mapiraj osnovna svojstva
            var response = mapper.Map<UserResponse>(user);

            // 7) Dohvati imena rola i potom entitete da popuniš detalje
            var roleNames = await _userManager.GetRolesAsync(user);
            var roleEntities = await _roleManager.Roles
                .Where(r => roleNames.Contains(r.Name))
                .ToListAsync();

            response.Roles = roleEntities
                .Select(r => new RolesResponse
                {
                    RoleName = r.Name,
                    Description = r.Description
                })
                .ToList();

            // — opcionalno: generiraj JWT ako želiš odmah poslati token —
            // (isto kao u LoginAsync)

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

            // 7) Sastavi listu RoleResponse i ubaci u response
            response.Roles = roleEntities
                .Select(r => new RolesResponse
                {
                    RoleName = r.Name,
                    Description = r.Description
                })
                .ToList();

            // ——— Dodaj generiranje JWT tokena ———
            var authClaims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, request.Email),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };
            authClaims.AddRange(roleNames.Select(role => new Claim(ClaimTypes.Role, role)));

            var jwtToken = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                expires: DateTime.UtcNow
                            .AddMinutes(double.Parse(_configuration["Jwt:ExpireMinutes"]!)),
                claims: authClaims,
                signingCredentials: new SigningCredentials(
                    new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!)
                    ),
                    SecurityAlgorithms.HmacSha256
                )
            );

            response.Token = new JwtSecurityTokenHandler().WriteToken(jwtToken);
            response.Expiration = jwtToken.ValidTo;
            // ————————————————————————————————

            return response;
        }

    }
}
