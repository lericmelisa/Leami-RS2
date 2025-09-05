using Leami.Model.Entities;
using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services.IServices;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace LeamiWebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UserController : BaseCRUDController<UserResponse, UserSearchObject, UserRegistrationRequest, UserUpdateRequest>
    {
        private readonly IUserService _userService;  
        public UserController(IUserService userService):base(userService)
        {           
            _userService = userService;
        }

        [HttpPut("{id}")]
        public override async Task<UserResponse> Update(int id, [FromBody] UserUpdateRequest request)
        {
            try
            {
                return await _userService.UpdateAsync(id, request);
            }
            catch (DbUpdateException ex) when (ex.InnerException is SqlException sql && (sql.Number == 2601 || sql.Number == 2627))
            {
                Response.StatusCode = StatusCodes.Status409Conflict;
                await Response.WriteAsJsonAsync(new ProblemDetails
                {
                    Status = StatusCodes.Status409Conflict,
                    Title = "Conflict",
                    Detail = "Email/korisničko ime je već u upotrebi."
                });
                return default!;
            }
        }
        [AllowAnonymous]
        [HttpPost("Registration")]
        public override async Task<UserResponse> Create([FromBody] UserRegistrationRequest request)
        {
            try
            {
                return await _userService.CreateAsync(request);
            }
            catch (DbUpdateException ex) when (ex.InnerException is SqlException sql && (sql.Number == 2601 || sql.Number == 2627))
            {
                Response.StatusCode = StatusCodes.Status409Conflict;
                await Response.WriteAsJsonAsync(new ProblemDetails
                {
                    Status = StatusCodes.Status409Conflict,
                    Title = "Conflict",
                    Detail = "Email/korisničko ime je već u upotrebi."
                });
                return default!;
            }
            catch (InvalidOperationException ex) // <-- DODANO
            {
                Response.StatusCode = StatusCodes.Status409Conflict;
                await Response.WriteAsJsonAsync(new ProblemDetails
                {
                    Status = StatusCodes.Status409Conflict,
                    Title = "Conflict",
                    Detail = ex.Message
                });
                return default!;
            }
        }

        [Authorize]
        [HttpPost("change-password")]
        [ProducesResponseType(typeof(ChangePasswordResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest req)
        {
            var dto = await _userService.ChangePasswordAsync(req);
            return Ok(dto);
        }

     

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<ActionResult<UserResponse>> Login([FromBody] UserLoginRequest req)
        {
            var result = await _userService.LoginAsync(req);    
            if (result == null) return Unauthorized();
            return Ok(result);
        }
        [Authorize]
        [HttpPost("logout")]
        public async Task<IActionResult> Logout([FromServices] IUserService users)
        {
            await users.LogoutAsync();
            return Ok();
        }




    }
}
