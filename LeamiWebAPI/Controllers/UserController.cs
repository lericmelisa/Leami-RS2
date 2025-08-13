using Leami.Model.Entities;
using Leami.Model.Requests;
using Leami.Model.Responses;
using Leami.Model.SearchObjects;
using Leami.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace LeamiWebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UserController : BaseCRUDController<UserResponse, UserSearchObject, UserRegistrationRequest, UserRegistrationRequest>
    {
        private readonly IUserService _userService;  
        public UserController(IUserService userService):base(userService)
        {           
            _userService = userService;
        }
        [HttpPost("Registration")]
        public async Task<UserResponse> Register([FromBody] UserRegistrationRequest request)
        {
            return await _userService.CreateAsync(request);
        }
        //[HttpPost("register/guest")]
        //[AllowAnonymous]
        //public async Task<IActionResult> RegisterGuest([FromBody] UserRegistrationRequest dto)
        //{
        //    var result = await _userService.CreateWithRoleAsync(dto, "Guest");
        //    return result.Succeeded ? Ok(result.User) : BadRequest(result.Errors);
        //}

        //[HttpPost("register/employee")]
        //[Authorize(Roles = "Admin")]
        //public async Task<IActionResult> RegisterEmployee([FromBody] UserRegistrationRequest dto)
        //{
        //    var result = await _userService.CreateWithRoleAsync(dto, "Employee");
        //    return result.Succeeded ? Ok(result.User) : BadRequest(result.Errors);
        //}

        //[HttpPost("register/admin")]
        //[Authorize(Roles = "Admin")]
        //public async Task<IActionResult> RegisterAdmin([FromBody] UserRegistrationRequest dto)
        //{
        //    var result = await _userService.CreateWithRoleAsync(dto, "Admin");
        //    return result.Succeeded ? Ok(result.User) : BadRequest(result.Errors);
        //}

        [HttpPost("login")]
        public async Task<ActionResult<UserResponse>> Login([FromBody] UserLoginRequest req)
        {
            var result = await _userService.LoginAsync(req);    
            if (result == null) return Unauthorized();
            return Ok(result);
        }


    }
}
