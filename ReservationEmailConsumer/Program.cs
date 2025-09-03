using Microsoft.Extensions.Configuration;
using DotNetEnv;
class Program
{
    static void Main(string[] args)
    {
        Env.Load();
        var configuration = new ConfigurationBuilder()
           .AddEnvironmentVariables()
           .Build();



        var emailService = new EmailService(configuration);

        var reservationEmailConsumer = new ReservationEmailConsumer(configuration, emailService);
        reservationEmailConsumer.SendEmail();
        Console.WriteLine("Reservation Email Consumer started");
        Thread.Sleep(Timeout.Infinite);

        //// 3) Pošalji testni mail
        //Console.WriteLine("Slanje testnog maila...");
        //try
        //{
        //    emailService.SendEmail(
        //        recipientEmail: "lericmelisa02@gmail.com",
        //        message: "Ovo je test – javno mi kažeš jesi li dobio poruku."
        //    );
        //    Console.WriteLine("Testni mail je poslan. Provjeri Inbox ili Spam.");
        //}
        //catch (Exception ex)
        //{
        //    Console.WriteLine($"Greška pri slanju testnog maila: {ex.Message}");
        //}

        //// 4) Čekaj da vidiš rezultate (po potrebi)
        //Console.WriteLine("Pritisni bilo koju tipku za kraj…");
        //Console.ReadKey();

    }
}