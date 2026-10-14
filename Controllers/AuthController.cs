using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.RateLimiting;
using DashCash.Data;
using DashCash.Services;

namespace DashCash.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly TokenService _tokenService;

        public AuthController(AppDbContext context, TokenService tokenService)
        {
            _context = context;
            _tokenService = tokenService;
        }

    [EnableRateLimiting("AuthPolicy")]
[HttpPost("register")]
public async Task<IActionResult> Register([FromBody] RegisterDto dto)
{
    if (dto.Password != dto.ConfirmPassword)
    {
        return BadRequest(new { message = "Passwords do not match." });
    }

    // Check if user already exists
    var existingUser = await _context.Users.FirstOrDefaultAsync(u => u.PhoneNumber == dto.PhoneNumber);
    if (existingUser != null)
    {
        return BadRequest(new { message = "An account with this mobile number already exists." });
    }

    // Generate 6-digit OTP for SMS verification
    var otpCode = new Random().Next(100000, 999999).ToString();
    Console.WriteLine($"[DEV SMS OTP] Verification code for {dto.PhoneNumber}: {otpCode}");

    return Ok(new { 
        message = "Registration initiated. Please enter the OTP sent via SMS.",
        phoneNumber = dto.PhoneNumber 
    });
}

        [EnableRateLimiting("AuthPolicy")]
        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpDto dto)
        {
            // Validate OTP against user record, mark IsVerified = true, and issue JWT token if desired
            return Ok(new { message = "Account successfully verified!" });
        }

        [EnableRateLimiting("AuthPolicy")]
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] AuthDto model)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == model.Email);
            if (user == null || !BCrypt.Net.BCrypt.Verify(model.Password, user.PasswordHash))
            {
                return Unauthorized(new { message = "Invalid email or password." });
            }

            var token = _tokenService.GenerateToken(user.Email);
            return Ok(new { token });
        }
    }

    public class AuthDto
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
    public class RegisterDto
{
    public string PhoneNumber { get; set; } = string.Empty; // 11-digit mobile number
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string ConfirmPassword { get; set; } = string.Empty;
    public string Mpin { get; set; } = string.Empty; // 4-digit MPIN
}

    public class VerifyOtpDto
    {
        public string Email { get; set; } = string.Empty;
        public string OtpCode { get; set; } = string.Empty;
    }
}