using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Leami.Services.Migrations
{
    /// <inheritdoc />
    public partial class reviewUpdate2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DeletionReason",
                table: "Reviews",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeletionReason",
                table: "Reviews");
        }
    }
}
