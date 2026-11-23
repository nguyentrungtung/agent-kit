package com.example; // agent-kit: set to the project's base package and move to src/test/java/<base>/

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.fields;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.Architectures.layeredArchitecture;
import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

/** Architecture rules from .agent/rules — executable, run by `kit-run arch` and CI. */
@AnalyzeClasses(packages = "com.example", importOptions = ImportOption.DoNotIncludeTests.class)
class ArchitectureTest {

  @ArchTest
  static final ArchRule layers =
      layeredArchitecture()
          .consideringOnlyDependenciesInLayers()
          .layer("Api").definedBy("..api..", "..web..", "..controller..")
          .layer("Application").definedBy("..application..", "..service..")
          .layer("Domain").definedBy("..domain..")
          .layer("Infrastructure").definedBy("..infrastructure..", "..persistence..")
          .whereLayer("Api").mayNotBeAccessedByAnyLayer()
          .whereLayer("Application").mayOnlyBeAccessedByLayers("Api")
          .whereLayer("Infrastructure").mayNotBeAccessedByAnyLayer()
          .whereLayer("Domain").mayOnlyBeAccessedByLayers("Application", "Infrastructure", "Api");

  @ArchTest
  static final ArchRule noCycles = slices().matching("com.example.(*)..").should().beFreeOfCycles();

  @ArchTest
  static final ArchRule noFieldInjection =
      fields().should().notBeAnnotatedWith("org.springframework.beans.factory.annotation.Autowired")
          .because("use constructor injection");

  @ArchTest
  static final ArchRule domainIsFrameworkFree =
      noClasses().that().resideInAPackage("..domain..")
          .should().dependOnClassesThat().resideInAnyPackage("org.springframework..", "jakarta.servlet..")
          .because("domain must be testable without Spring")
          .allowEmptyShould(true);

  @ArchTest
  static final ArchRule noStdStreams =
      noClasses().should().accessField(System.class, "out").orShould().accessField(System.class, "err")
          .because("use SLF4J");
}
