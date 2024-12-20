using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Moq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using WebApplication1.Controllers;
using WebApplication1.Models; // Изменено пространство имен
using Xunit;
using Npgsql;
using WebApplication1.DB;
using System.Data;
using Microsoft.AspNetCore.Connections;
using static WebApplication1.Tests.RegistrationControllerTests;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Primitives;


namespace WebApplication1.Tests
{
    public class RegistrationControllerTests : IDisposable
    {

        private DbContextOptions<ApplicationDbContext> _options;
        private ApplicationDbContext _context;

        public RegistrationControllerTests()
        {
            _options = new DbContextOptionsBuilder<ApplicationDbContext>()
                   .UseInMemoryDatabase(databaseName: "TestDb", builder => builder.EnableNullChecks(false))
                   .Options;
            _context = new ApplicationDbContext(_options);
        }
        private Mock<IDbConnection> CreateMockConnection()
        {
            var mockConnection = new Mock<IDbConnection>();
            mockConnection.Setup(conn => conn.Open()).Verifiable();
            mockConnection.Setup(conn => conn.Close()).Verifiable();
            return mockConnection;
        }

        [Fact]
        public async Task InsertData_ValidData_ReturnsOk()
        {
            // Arrange
            var mockConnection = CreateMockConnection();
            var mockCommand = new Mock<IDbCommand>();

            mockConnection.Setup(conn => conn.CreateCommand()).Returns(mockCommand.Object);
            mockCommand.Setup(cmd => cmd.ExecuteNonQuery()).Returns(1);

            var controller = new RegistrationController();
            var username = "testuser";
            var email = "test@example.com";
            var password = "testpass";

            var formCollection = new Dictionary<string, StringValues>
             {
                   { "username", username },
                   { "email", email },
                   { "password", password }
                };

            var form = new FormCollection(formCollection);
            var httpContext = new Mock<HttpContext>();
            // Store data in the context
            httpContext.SetupGet(x => x.Request.Form).Returns(form);
            controller.ControllerContext = new ControllerContext { HttpContext = httpContext.Object };

            // Act
            var result = controller.InsertData(username, password, email) as OkObjectResult;

            // Assert
            Assert.NotNull(result);
            Assert.Equal("Данные успешно добавлены.", result.Value);

            var user = _context.Users.FirstOrDefault(u => u.username == username);
            Assert.NotNull(user);
            Assert.Equal(username, user.username);
            Assert.Equal(email, user.email);
            Assert.Equal("читатель", user.role);
        }


        [Fact]
        public void InsertData_SqlInjection_ReturnsBadRequest()
        {
            // Arrange

            var controller = new RegistrationController();

            // Act
            var result = controller.InsertData("testuser", "DROP TABLE users;", "test@example.com") as BadRequestObjectResult;

            // Assert
            Assert.NotNull(result);
            Assert.Equal("Попытка SQL-инъекции обнаружена.", result.Value);

        }

        [Fact]
        public void InsertData_Exception_ReturnsBadRequest()
        {
            // Arrange
            var controller = new RegistrationController();
            // Act
            var result = controller.InsertData("testuser", "testpass", "test@example.com") as BadRequestObjectResult;
            // Assert
            Assert.NotNull(result);
            Assert.Contains("Ошибка при вставке данных", result.Value.ToString());

        }

        public void Dispose()
        {
            // Очищаем контекст и удаляем базу данных в памяти
            _context.Dispose();
        }
    }
}