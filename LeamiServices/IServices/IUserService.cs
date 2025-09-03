using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.Entities;

using Leami.Model.SearchObjects;
using Microsoft.AspNetCore.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace Leami.Services.IServices
{
    public interface IUserService : ICRUDService<UserResponse, UserSearchObject, UserRegistrationRequest, UserUpdateRequest>
    {
        Task<UserResponse?> LoginAsync(UserLoginRequest request);
        Task LogoutAsync();
        //Task<IdentityResult> RegisterAsync(RegisterDto dto);
        //Task<SignInResult> LoginAsync(LoginDto dto);
        //Task LogoutAsync();
        //Task<ApplicationUser?> GetCurrentUserAsync(ClaimsPrincipal userPrincipal);
    }
}
