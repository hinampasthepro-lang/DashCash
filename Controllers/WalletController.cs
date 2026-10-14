using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DashCash.Data;
using System.Security.Claims;

namespace DashCash.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class WalletController : ControllerBase
    {
        private readonly AppDbContext _context;

        public WalletController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetBalance()
        {
            var userEmail = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue(ClaimTypes.Email);
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == userEmail);
            if (user == null) return Unauthorized();

            var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == user.Id);
            if (wallet == null)
            {
                wallet = new Wallet { UserId = user.Id, Balance = 1000.00m };
                _context.Wallets.Add(wallet);
                await _context.SaveChangesAsync();
            }

            return Ok(new { balance = wallet.Balance, currency = "USD" });
        }
    }
}