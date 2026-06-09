# Photo Classification Platform

This repository contains the foundation for a distributed Photo Classification Platform. 

## Architecture

The platform uses a decoupled, microservices-based architecture containerized via Docker:

* **`frontend/`**: Flutter application.
* **`backend/user_service/`**: A lightweight FastAPI instance running on port `8000`. This will handle registration, logins, and JWT token management.
* **`backend/classification_service/`**: A separate FastAPI instance running on port `8001`. This will handle the heavy lifting: image uploads, metadata processing, and running classification logic.
* **Local Storage Volume**: A named Docker volume (`photo_storage`) shared with the classification service. For local development, it maps directly to `/app/shared_storage` inside the container, saving images directly to disk without requiring external cloud accounts.

The following image explains it visually: [Diagram](./photo_class_arch.jpg)

---

## How to Run Locally

Docker handles everything inside its own virtual containers.

1. Make sure **Docker Desktop** is open and running.
2. Spin up the cluster by running this command in the project root:
   ```bash
   docker compose up --build
   ```

3. To shut down the services and clear the network space, simply run:   
   ```bash
   docker compose down
   ```
### Note on the Frontend Flutter Setup (FVM)
If you are developing the frontend code, running the web app locally, or running builders, please note that this project uses FVM (Flutter Version Management). This is important because it makes sure everyone on the team uses the exact same Flutter SDK version.

Because of this, do not use the standard global **`flutter`** commands. Always use the **`fvm`** prefix in your terminal:
```
fvm flutter run -d chrome
```
To update Riverpod generated files (build_runner):
```
fvm dart run build_runner build --delete-conflicting-outputs
```

 **How to install FVM:**
 https://fvm.app/documentation/getting-started/installation

## Managing Environment Variables (Currenly it uses placeholder hardcoded values)   

Right now in the code, we use some placeholder text values for things like secrets (for example, the **`JWT_SECRET`** key). This is okay for testing on your own machine, but not for production.

To change this, you should create a **`.env`** file inside the root folder of the project:

   ```env
   // Database setups
   POSTGRES_USER=my_db_user
   POSTGRES_PASSWORD=my_secure_password
   POSTGRES_DB=photoclass_db

   // Security keys
   JWT_SECRET=put_a_very_long_random_string_here_for_production
   ```


Inside the **`docker-compose.yml`** file, make sure the services know how to read this file by adding the **`env_file`** setting:
   
  ```
   user-service:
  build: ./backend/user_service
  env_file:
    - .env
  ports:
    - "8000:8000"
  ```  


##  Microservices & Swagger Docs

Our backend runs on **2 distinct microservices** using FastAPI. They are very fast and lightweight. Each service creates its own automatic interactive webpage documentation (Swagger UI). You can go to these URLs to see all available API endpoints and test them directly from the browser:

| Microservice Name | Local Port | Swagger Documentation URL |
| :--- | :--- | :--- |
| **User Service** (Handles registrations, logins, profile updates) | `8000` | [http://localhost:8000/docs](http://localhost:8000/docs) |
| **Classification Service** (Handles photo uploads, Classification results (mocked for now), admin filters) | `8001` | [http://localhost:8001/docs](http://localhost:8001/docs) |

## Database Design & Storage
We use a PostgreSQL database to save all user records and Docker Volume for photo data storage.

### The Schema Concept (1-to-Many Relation)
The database structure is quite simple. We have 2 main tables:

* Users Table: Stores the account details, hashed passwords, and personal user metadata (age, gender, place of living, country code, and short description biography).


####  `users` Table
| Column Name | Data Type | Attributes & Indexing |
| :--- | :--- | :--- |
| **`id`** | `Integer` | Primary Key, Auto-Increment, Indexed |
| `username` | `String` | Unique, Indexed, Required |
| `hashed_password` | `String` | Required |
| `name` | `String` | Required |
| `age` | `Integer` | **Indexed**, Required |
| `gender` | `String` | **Indexed**, Required |
| `place_of_living`| `String` | **Indexed**, Required |
| `country_code` | `String(2)`| **Indexed**, Required |
| `description` | `String` | Optional (Nullable) |
| `role` | `String` | Default: `"user"`, Required |


* Submissions Table: Stores information about the uploaded photo file path, what the AI classified the image with, a timestamp, and a user_id relation key.

####  `submissions` Table
| Column Name | Data Type | Attributes & Indexing |
| :--- | :--- | :--- |
| **`id`** | `Integer` | Primary Key, Auto-Increment, Indexed |
| `user_id` | `Integer` | **Foreign Key** (`users.id` with CASCADE), **Indexed**, Required |
| `image_path` | `String` | Required |
| `classification_title` | `String` | Required |
| `timestamp` | `DateTime` | Default: `UTC Now`, **Indexed**, Required |

* **Relationship:** `1` User can have `N` Submissions (One-to-Many).  

### Database Indexes
To keep the application super fast even when users upload thousands of photos, we added indexes to columns that we filter or search a lot:

  * **` user_id `** on the Submissions table (makes loading a user's personal layout history extremely fast).

  * **`age`**, **`gender`**, and **`country_code`** on the Users table (so when the Admin dashboard runs filter queries, it stays fast and doesn't slow down the database performance).

### How to do a DB Migration
If you need to change the database structure later—for example, if we want to add a new column like phone_number to the users table—you should do a migration so you don't destroy the existing data.

If using Alembic updates:
Inside the specific backend microservice folder, run these commands:

   ```
   alembic revision --autogenerate -m "add phone number column"
   alembic upgrade head
   ```

Remember to update the schemas in the code so they match the new column change.

## API Security
Security is forced at the backend level, which is the most safe way to build things.

*   JWT Tokens: When a user logs in successfully, they get back a cryptographically signed token. The frontend saves this and sends it inside the **`Authorization: Bearer <token>`** header for every request. Tokens expire in 60min.

*   User Privacy Guard: The API endpoints always check the **`user_id`** from the decrypted token payload. A normal logged-in user can only view, fetch, or delete their own data and photos. They can never guess another user's ID to view private history log data.

*   Admin Enforcement: The global admin endpoint (**`/api/submissions/admin`**) has an extra strict check dependency. It takes the token, looks up the user account in the PostgreSQL table, and checks if **` user.role == 'admin'`**. If a normal user tries to access this route, they get a 403 Forbidden error immediately.


## Frontend Architecture (Flutter & Riverpod)
The frontend is built using Flutter Web, but because the codebase is clean, it can be easily compiled for Mobile (iOS and Android) later without rewriting the logic.

### State Management
We use Riverpod with code generation (**`build_runner`**). This helps us handle asynchronous data streams from the backend without messy code. When you do an action, like dropping a file or deleting a card, Riverpod automatically updates only the specific widgets that changed, keeping the app snappy.

### Folder Structure
The code inside the **`lib/`** directory is cleanly split up to separate global settings from app features:

* **`core/`**: Holds things used across the entire application, like global color themes (app_colors.dart), structural layout spacings, and the automated network API clients.

* **`features/`**: This is split by independent app modules:

   * **`auth/`**: Login screens, registration forms, user settings profile view, and profile view models.

   * **`photo_submission/`**: Main user dashboard workspace, grid logs, and the single-file drag-and-drop upload zone widgets.

   * **`admin_panel/`**: Global overview lists, admin detailed dialog boxes, and demographic filtering console views.

### Adaptive Layout Design
Every screen component is designed to be adaptive. Even though only Web layout is required for now, widgets use things like LayoutBuilder or check size parameters. For example, on a wide desktop browser screen, input fields and demographic filters are shown side-by-side inside a Row, but on a narrow mobile screen, they automatically wrap and stack vertically in a Column so the user interface never clips or breaks.

## CI/CD Automation Strategy

The following document explains it in depth: [CI/CD Documentation](./CI-CD.md)