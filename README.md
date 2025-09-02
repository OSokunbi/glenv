# gleamv

gleam wrapper for managing environment variables. load variables from `.env` files and access them in your Gleam applications.

```sh
gleam add gleamv@1
```
```gleam
import gleamv

pub fn main() -> Nil {
  case gleamv.init() {
    Ok(_) -> Nil
    Error(e) -> io.println("Error loading .env file: " <> string.inspect(e))
  }
  
  let assert Ok(db_url) = gleamv.require("DATABASE_URL")
  io.println("Database URL: " <> db_url)
}
```

## feats

- load environment variables from a `.env` file.
- override existing environment variables.
- access environment variables with type safety (String, Int, Bool).
- provide default values for environment variables.
- require environment variables to be set.

## deps

this package relies on the following dependencies:
- `simplifile`: For file system operations.

## Installation

Add `gleamv` to your Gleam project's dependencies in `gleam.toml`:

```toml
[dependencies]
gleamv = "x.x.x"
```

## usage

### 1. create a `.env` file

create a `.env` file in the root of your project:

```
DATABASE_URL="your-database-url"
PORT="8080"
DEBUG="true"
```

### 2. initialize gleamv

initialize gleamv in your application's entry point (e.g., `main` function):

```gleam
import gleamv

pub fn main() {
  case gleamv.init() {
    Ok(_) -> {
      // Glenv is initialized successfully
    }
    Error(err) -> {
      // Handle initialization error
    }
  }
}
```

### 3. access env variables

access env variables using the `get`, `get_int`, and `get_bool` functions:

```gleam
import gleamv

pub fn main() {
  case env.init() {
    Ok(_) -> Nil
    Error(e) -> io.println("Error loading .env file: " <> string.inspect(e))
  }
  
  let db_url = gleamv.get("DATABASE_URL")
  // Some("your-database-url")

  let port = gleamv.get_int("PORT")
  // Ok(8080)

  let debug = gleamv.get_bool("DEBUG")
  // Ok(True)
}
```

### 4. provide default values

Use the `get_or`, `get_int_or`, and `get_bool_or` functions to provide default values:

```gleam
import gleamv

pub fn main() {
  let host = gleamv.get_or("HOST", "localhost")
  // "localhost"

  let port = gleamv.get_int_or("PORT", 8080)
  // 8080

  let debug = gleamv.get_bool_or("DEBUG", False)
  // False
}
```

### 5. require env variables

use the `require` function to ensure that a required environment variable is set:

```gleam
import gleamv

pub fn main() {
  case gleamv.require("API_KEY") {
    Ok(api_key) -> {
      // Use the api_key
    }
    Error(err) -> {
      // Handle missing required environment a variable
    }
  }
}
```

## config

you can customize gleamv's behavior by providing a `Config` to the `init_with_config` function:

```gleam
import gleamv

pub fn main() {
  let config = gleamv.Config(
    path: ".env.local",
    override: True,
    ignore_missing: False,
  )

  case gleamv.init_with_config(config) {
    Ok(_) -> {
      // gleamv is initialized with custom config
    }
    Error(err) -> {
      // handle initialization error
    }
  }
}
```

- `path`: the path to your `.env` file (default: `.env`).
- `override`: whether to override existing environment variables (default: `False`).
- `ignore_missing`: whether to ignore a missing `.env` file (default: `True`).
