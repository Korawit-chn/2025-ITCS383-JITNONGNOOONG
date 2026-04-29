# Phase 2 Mobile Application Implementation

## Project Context

Existing system: Dog Adoption Platform (Node.js + Express + MySQL + Vanilla JS)

---

# Task 1: Create mobile application
* Implement mobile application using flutter in "implementations/src/mobile" folder
* Use the same design as web frontend design
* Implement all the features same as web application
* Using the existing backend server for feature implementation 

# Task 2: Matching mobile feature to current web application
* Matching all the pages and function from web application
* Using the same url as frontend to fetch to backend service
* All the pages must match the frontend pages both function and design

    # Task 2.1: Admin dashboard (Look at the web application for reference and match it).
        * Admin user be able to check the overall graph same as web app and potential adopter in admin dashboard

    # Task 2.2: Staff dashboard (Look at the web application for reference and match it).     
        * Manage/Add/Edit/Delete dogs info.
        * Staff manage adoption request.
        * Checking and validate requester id.
        * Approve/Deny the dog recieve date with user.
        * View After Adoption following report.

    # Task 2.3: User dashboard (Look at the web application for reference and match it).
        * View their favorite dogs.
        * View their own adoption request.
        * Select the dog recieve date with staff.
        * The After Adopt following session.
        * Be able to go back to home page for further adoption.

    # Task 2.4: Sponsor dashboard (Look at the web application for reference and match it).
        * Manage the money for sponsoring.
        * Manage and upload the ad banner.

# Task 3: Working adoption system
* Dog screen page be able to click to view the selected dog info and select to adopt.
* User account can mark favorite on the dog info page.
* The adoption flow must match the web application.

---

# Refactoring (from SonarQube report)

* Fix 36 reliability issues
* Reduce duplicated logic
* Break functions with high complexity (>50)
