using System.ComponentModel.DataAnnotations;

namespace DashCash.Dtos;

public class RegisterRequest
{
    [Required, StringLength(100)]
    public string FullName { get; set; } = string.Empty;

    [Required, StringLength(100)]
    public string Identifier { get; set; } = string.Empty;

    [Required, StringLength(72, MinimumLength = 8)]
    public string Password { get; set; } = string.Empty;
}