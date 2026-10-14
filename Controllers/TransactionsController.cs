using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DashCash.Data;
using DashCash.Models;
using System.Security.Claims;

namespace DashCash.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class TransactionsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public TransactionsController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetTransactions()
        {
            var userEmail = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue(ClaimTypes.Email);
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == userEmail);
            if (user == null) return Unauthorized();

            var userTransactions = await _context.Transactions
                .Where(t => t.UserId == user.Id)
                .OrderByDescending(t => t.Date)
                .ToListAsync();

            return Ok(userTransactions);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetTransactionReceipt(int id)
        {
            var userEmail = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue(ClaimTypes.Email);
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == userEmail);
            if (user == null) return Unauthorized();

            var transaction = await _context.Transactions
                .FirstOrDefaultAsync(t => t.Id == id && t.UserId == user.Id);

            if (transaction == null) return NotFound(new { message = "Transaction not found." });

            return Ok(new
            {
                id = transaction.Id,
                title = transaction.Title,
                amount = transaction.Amount,
                type = transaction.Type,
                date = transaction.Date,
                referenceCode = $"DC-TXN-{transaction.Id}-{transaction.Date.Ticks.ToString()[^6..]}"
            });
        }

        [HttpPost]
        public async Task<IActionResult> CreateTransaction([FromBody] TransactionDto dto)
        {
            if (dto.Amount <= 0)
            {
                return BadRequest(new { message = "Transaction amount must be greater than zero." });
            }

            var userEmail = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue(ClaimTypes.Email);
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == userEmail);
            if (user == null) return Unauthorized();

            // Find or create user wallet
            var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == user.Id);
            if (wallet == null)
            {
                wallet = new Wallet { UserId = user.Id, Balance = 1000.00m }; // Default starting balance
                _context.Wallets.Add(wallet);
            }

            // Backend Validation for Withdrawals
            if (dto.Type == "Withdrawal" && wallet.Balance < dto.Amount)
            {
                return BadRequest(new { message = "Insufficient funds for this withdrawal." });
            }

            // Calculate final balance change
            decimal signedAmount = dto.Type == "Withdrawal" ? -dto.Amount : dto.Amount;
            wallet.Balance += signedAmount;

            var transaction = new Transaction
            {
                UserId = user.Id,
                Title = dto.Title,
                Amount = signedAmount,
                Type = dto.Type,
                Date = DateTime.UtcNow
            };

            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Transaction created successfully", newBalance = wallet.Balance, transaction });
        }

        [HttpPost("transfer")]
        public async Task<IActionResult> TransferFunds([FromBody] TransferDto dto)
        {
            if (dto.Amount <= 0)
                return BadRequest(new { message = "Transfer amount must be greater than zero." });

            var senderEmail = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue(ClaimTypes.Email);
            if (senderEmail == null || senderEmail.Equals(dto.RecipientEmail, StringComparison.OrdinalIgnoreCase))
                return BadRequest(new { message = "You cannot transfer money to yourself." });  

            var sender = await _context.Users.FirstOrDefaultAsync(u => u.Email == senderEmail);
            var recipient = await _context.Users.FirstOrDefaultAsync(u => u.Email == dto.RecipientEmail);

            if (sender == null || recipient == null)
                return BadRequest(new { message = "Recipient email not found." });

            var senderWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == sender.Id);
            if (senderWallet == null || senderWallet.Balance < dto.Amount)
                return BadRequest(new { message = "Insufficient funds for this transfer." });

            var recipientWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == recipient.Id);
            if (recipientWallet == null)
            {
                recipientWallet = new Wallet { UserId = recipient.Id, Balance = 1000.00m };
                _context.Wallets.Add(recipientWallet);
            }

            // Execute transfer
            senderWallet.Balance -= dto.Amount;
            recipientWallet.Balance += dto.Amount;

            // Record dynamic ledger entries for both parties
            _context.Transactions.Add(new Transaction
            {
                UserId = sender.Id,
                Title = $"Transfer to {recipient.Email}",
                Amount = -dto.Amount,
                Type = "Transfer",
                Date = DateTime.UtcNow
            });

            _context.Transactions.Add(new Transaction
            {
                UserId = recipient.Id,
                Title = $"Transfer from {sender.Email}",
                Amount = dto.Amount,
                Type = "Transfer",
                Date = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return Ok(new { message = "Transfer successful!", newBalance = senderWallet.Balance });
        }
    }

    public class TransferDto
    {
        public string RecipientEmail { get; set; } = string.Empty;
        public decimal Amount { get; set; }
    }

    public class TransactionDto
    {
        public string Title { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string Type { get; set; } = "Deposit";
    }
}