.DEFAULT_GOAL := intro

intro:
	@echo "please specify a target {start-api, migrate-up, migrate-down, test, build, install, swagger}"

swagger:
	@echo "Swagger UI is served at http://localhost:8080/swagger when the API is running."
	@echo "Raw spec is available at http://localhost:8080/swagger.json"

start-api:
	go run app.go api

migrate-up:
	go run app.go migrate up

migrate-down:
	go run app.go migrate down

test:
	go test ./...

clean-test-cache:
	go clean -testcache && go test ./...

test-wo-cache: clean-test-cache

build:
	go build -o=$(app_name) .

install:
	go build -ldflags="-s -w" -o=$(app_name) .
