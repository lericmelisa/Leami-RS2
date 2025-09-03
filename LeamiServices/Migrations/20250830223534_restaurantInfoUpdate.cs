using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Leami.Services.Migrations
{
    /// <inheritdoc />
    public partial class restaurantInfoUpdate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "AdminUserId",
                table: "RestaurantInfos",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_RestaurantInfos_AdminUserId",
                table: "RestaurantInfos",
                column: "AdminUserId",
                unique: true,
                filter: "[AdminUserId] IS NOT NULL");

            migrationBuilder.AddForeignKey(
                name: "FK_RestaurantInfos_Users_AdminUserId",
                table: "RestaurantInfos",
                column: "AdminUserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_RestaurantInfos_Users_AdminUserId",
                table: "RestaurantInfos");

            migrationBuilder.DropIndex(
                name: "IX_RestaurantInfos_AdminUserId",
                table: "RestaurantInfos");

            migrationBuilder.DropColumn(
                name: "AdminUserId",
                table: "RestaurantInfos");
        }
    }
}
