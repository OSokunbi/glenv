# glenv

[![Package Version](https://img.shields.io/hexpm/v/glenv)](https://hex.pm/packages/glenv)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glenv/)

# glenv

gleam wrapper for managing environment variables. load variables from `.env` files and access them in your Gleam applications.

```sh
gleam add glenv@1
```
```gleam
import glenv

pub fn main() -> Nil {
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

Add `glenv` to your Gleam project's dependencies in `gleam.toml`:

```toml
[dependencies]
glenv = "x.x.x"
```

## usage

### 1. create a `.env` file

create a `.env` file in the root of your project:

```
DATABASE_URL="your-database-url"
PORT="8080"
DEBUG="true"
```

### 2. initialize glenv

initialize glenv in your application's entry point (e.g., `main` function):

```gleam
import glenv

pub fn main() {
  case glenv.init() {
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
import glenv
import gleam/option.{Some, None}

pub fn main() {
  case env.init() {
    Ok(_) -> Nil
    Error(e) -> io.println("Error loading .env file: " <> string.inspect(e))
  }
  
  let db_url = glenv.get("DATABASE_URL")
  // Some("your-database-url")

  let port = glenv.get_int("PORT")
  // Ok(8080)

  let debug = glenv.get_bool("DEBUG")
  // Ok(True)
}
```

### 4. provide default values

Use the `get_or`, `get_int_or`, and `get_bool_or` functions to provide default values:

```gleam
import glenv

pub fn main() {
  let host = glenv.get_or("HOST", "localhost")
  // "localhost"

  let port = glenv.get_int_or("PORT", 8080)
  // 8080

  let debug = glenv.get_bool_or("DEBUG", False)
  // False
}
```

### 5. require env variables

use the `require` function to ensure that a required environment variable is set:

```gleam
import glenv

pub fn main() {
  case glenv.require("API_KEY") {
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

you can customize glenv's behavior by providing a `Config` to the `init_with_config` function:

```gleam
import glenv

pub fn main() {
  let config = glenv.Config(
    path: ".env.local",
    override: True,
    ignore_missing: False,
  )

  case glenv.init_with_config(config) {
    Ok(_) -> {
      // glenv is initialized with custom config
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
