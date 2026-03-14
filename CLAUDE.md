# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
mvn clean install          # build + test
mvn clean package -DskipTests  # build only (used in CI)
mvn test                   # run tests
docker build -t spring-boot-demo .
docker run -p 8080:8080 spring-boot-demo
```

## Architecture

Spring Boot 3.3.5 / Java 21 REST API backed by H2 in-memory DB. Single domain: `Author`.

**Layer flow:** `AuthorController` -> `AuthorService` (interface) -> `AuthorServiceImpl` -> `AuthorRepository` (JpaRepository) -> H2

**Package layout** (note: packages are non-conventionally named):
- `com.app.controller` - REST layer (`GET /author?author_id=`, `POST /author`)
- `com.app.service` - JPA repository interface (`AuthorRepository extends JpaRepository<Author, Integer>`)
- `com.app.repository.impl` - service implementation (`AuthorServiceImpl`)
- `com.app.entity` - JPA entity (`Author`: id, authorId, name)

**CI:** GitHub Actions on push to main builds with Maven, pushes Docker image to GHCR tagged `latest` and commit SHA.

**Deployment:** EC2 via Terraform (tf configs in repo).
