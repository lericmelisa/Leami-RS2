using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Leami.Services.Migrations
{
    /// <inheritdoc />
    public partial class reviewAdd : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Id",
                table: "Cities",
                newName: "CityId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "CityId",
                table: "Cities",
                newName: "Id");
        }
    }
}
