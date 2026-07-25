namespace BusinessLayer.Interfaces;

public interface IEmailService
{
    Task SendAsync(string toEmail, string subject, string bodyHtml, CancellationToken cancellationToken = default);
}
