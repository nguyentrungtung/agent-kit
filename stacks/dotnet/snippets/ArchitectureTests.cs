// agent-kit: add to a test project; dotnet add package NetArchTest.Rules
using NetArchTest.Rules;
using Xunit;

public class ArchitectureTests
{
    private const string Domain = "MyApp.Domain";
    private const string Infrastructure = "MyApp.Infrastructure";
    private const string Api = "MyApp.Api";

    [Fact]
    public void Domain_does_not_depend_on_outer_layers()
    {
        var result = Types.InAssembly(typeof(MyApp.Domain.AssemblyMarker).Assembly)
            .ShouldNot().HaveDependencyOnAny(Infrastructure, Api, "Microsoft.EntityFrameworkCore")
            .GetResult();
        Assert.True(result.IsSuccessful, string.Join(", ", result.FailingTypeNames ?? []));
    }
}
