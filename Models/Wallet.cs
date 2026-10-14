using System.ComponentModel.DataAnnotations;

namespace DashCash.Models
{
    public class Wallet
    {
        [Key]
        public int Id { get; set; }
        public int UserId { get; set; }
        public decimal Balance { get; set; } = 1000.00m; // Default starting balance for testing
    }
}