using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DashCash.Controllers
{
    [Authorize] // Requires a valid JWT token to access
    [Route("api/protected-endpoint")]
    [ApiController]
    public class ProtectedController : ControllerBase
    {
        [HttpGet]
        public IActionResult GetProtectedData()
        {
            // Extract the user's email or identity from the JWT claims
            var userEmail = User.Identity?.Name ?? "Authenticated User";
            
            return Ok(new { 
                message = "Success! You accessed a protected endpoint.", 
                user = userEmail 
            });
        }
    }
}