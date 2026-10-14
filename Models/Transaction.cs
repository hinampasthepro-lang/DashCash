using System.ComponentModel.DataAnnotations;

namespace DashCash.Models
{
    public class Transaction
    {
        [Key]
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Title { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public DateTime Date { get; set; } = DateTime.UtcNow;
        public string Type { get; set; } = "Deposit"; // e.g., "Deposit", "Withdrawal", "Transfer"
    }
}