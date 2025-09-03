using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Leami.Services.Migrations
{
    /// <inheritdoc />
    public partial class reservationUpdate3 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Reservations_ReservationId",
                table: "Notifications");

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Reservations_ReservationId",
                table: "Notifications",
                column: "ReservationId",
                principalTable: "Reservations",
                principalColumn: "ReservationId",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Reservations_ReservationId",
                table: "Notifications");

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Reservations_ReservationId",
                table: "Notifications",
                column: "ReservationId",
                principalTable: "Reservations",
                principalColumn: "ReservationId");
        }
    }
}
