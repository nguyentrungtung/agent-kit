// agent-kit: merge into build.gradle.kts
plugins {
    java
    checkstyle
    pmd
    jacoco
    id("com.diffplug.spotless") version "7.0.2"
    id("org.owasp.dependencycheck") version "12.1.0"
}

spotless {
    java {
        googleJavaFormat().reflowLongStrings()
        removeUnusedImports()
        importOrder()
        formatAnnotations()
    }
}

checkstyle {
    toolVersion = "10.21.4"
    config = resources.text.fromArchiveEntry(configurations.checkstyle.get().first(), "google_checks.xml")
    maxWarnings = 0
    isIgnoreFailures = false
}

dependencyCheck { failBuildOnCVSS = 7.0f }

dependencies {
    testImplementation("com.tngtech.archunit:archunit-junit5:1.3.0")
}

tasks.test {
    useJUnitPlatform()
    finalizedBy(tasks.jacocoTestReport)
}

tasks.jacocoTestCoverageVerification {
    violationRules {
        rule { limit { minimum = (project.findProperty("coverage.min") ?: "0.70").toString().toBigDecimal() } }
    }
}

pmd {
    ruleSetFiles = files("config/pmd-ruleset.xml")
    ruleSets = listOf()
    isConsoleOutput = true
}
