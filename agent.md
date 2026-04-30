# AI Agent Instructions

## Project Overview

This is a Dog Adoption system using:

* Backend: Node.js (Express)
* Database: MySQL
* Frontend: Vanilla JavaScript (HTML/CSS)
* Mobile: Flutter (dart)

---

## Architecture Rules

* Everything must do in 'implementations/src/mobile'
* Follow REST API design
* Separate layers:

  * Routes
  * Controllers
  * Services
  * Database queries
* Do not mix business logic inside routes

---

## Coding Standards

* Use async/await (no callback hell)
* Handle errors using try/catch
* Return consistent JSON format:
  {
  success: boolean,
  data: any,
  message: string
  }

---

## Database Rules

* Use parameterized queries (prevent SQL injection)
* Avoid raw string concatenation in SQL
* Use indexes for searchable fields (name, breed)

---

## Feature Implementation Rules

### Mobile application
* Making a mobile application with the exactly same feature as frontend web applicaiton 'implementations/src/frontend'.
* Only use existing API in backend folder 'implementations/src/backend' 
* All feature/funciton in web application (frontend part) must exists and working correctly in mobile

---

## Performance Guidelines

* Avoid unnecessary DB calls
* Use pagination if result is large
* Keep API response time fast (<300ms if possible)

---

## Refactoring Rules

* Reduce code duplication
* Split large functions into smaller reusable functions
* Improve readability and maintainability

---

## What NOT to do

* Do not change existing working features
* Do not break RBAC (role-based access control)
* Do not modify anything else that not inside 'mobile' folder
