import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile

/// config options for loading .env files
pub type Config {
  Config(path: String, override: Bool, ignore_missing: Bool)
}

/// default config
pub fn default_config() -> Config {
  Config(path: ".env", override: False, ignore_missing: True)
}

/// error types
pub type DotenvError {
  FileNotFound(String)
  ParseError(String, Int)
  IOError(String)
}

fn parse_line(
  line: String,
  line_number: Int,
) -> Result(Option(#(String, String)), DotenvError) {
  let trimmed = string.trim(line)

  case trimmed {
    "" -> Ok(None)
    _ -> {
      case string.starts_with(trimmed, "#") {
        True -> Ok(None)
        False -> {
          case string.split_once(trimmed, "=") {
            Ok(#(key, value)) -> {
              let cleaned_key = string.trim(key)
              let cleaned_value = clean_value(string.trim(value))

              case cleaned_key {
                "" -> Error(ParseError("Empty variable name", line_number))
                _ -> Ok(Some(#(cleaned_key, cleaned_value)))
              }
            }
            Error(_) ->
              Error(ParseError("Invalid line format (missing '=')", line_number))
          }
        }
      }
    }
  }
}

fn clean_value(value: String) -> String {
  case string.starts_with(value, "\"") && string.ends_with(value, "\"") {
    True -> {
      value
      |> string.drop_start(1)
      |> string.drop_end(1)
    }
    False -> {
      case string.starts_with(value, "'") && string.ends_with(value, "'") {
        True -> {
          value
          |> string.drop_start(1)
          |> string.drop_end(1)
        }
        False -> value
      }
    }
  }
}

fn parse(content: String) -> Result(Dict(String, String), DotenvError) {
  content
  |> string.split("\n")
  |> list.index_map(fn(line, index) { parse_line(line, index + 1) })
  |> list.try_fold(dict.new(), fn(acc, result) {
    case result {
      Ok(Some(#(key, value))) -> Ok(dict.insert(acc, key, value))
      Ok(None) -> Ok(acc)
      Error(err) -> Error(err)
    }
  })
}

/// load env variables from a .env file
pub fn load() -> Result(Dict(String, String), DotenvError) {
  load_with_config(default_config())
}

/// load env variables with custom config
pub fn load_with_config(
  config: Config,
) -> Result(Dict(String, String), DotenvError) {
  case simplifile.read(config.path) {
    Ok(content) -> parse(content)
    Error(simplifile.Enoent) -> {
      case config.ignore_missing {
        True -> Ok(dict.new())
        False -> Error(FileNotFound(config.path))
      }
    }
    Error(_) -> Error(IOError("Failed to read file: " <> config.path))
  }
}

/// load a .env and apply to system environment, will allow you to use system env functions
pub fn init() -> Result(Nil, DotenvError) {
  init_with_config(default_config())
}

/// load a .env with some config and apply to system environment
pub fn init_with_config(config: Config) -> Result(Nil, DotenvError) {
  use env_vars <- result.try(load_with_config(config))

  dict.each(env_vars, fn(key, value) {
    case get_system_env(key) {
      Ok(_) -> {
        case config.override {
          True -> {
            let _ = set_system_env(key, value)
            Nil
          }
          False -> Nil
        }
      }
      Error(_) -> {
        let _ = set_system_env(key, value)
        Nil
      }
    }
  })

  Ok(Nil)
}

/// get an environment variable from the system
pub fn get(key: String) -> Option(String) {
  case get_system_env(key) {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}

/// get an environment variable or return a default
pub fn get_or(key: String, default: String) -> String {
  case get(key) {
    Some(value) -> value
    None -> default
  }
}

pub fn get_int(key: String) -> Result(Int, Nil) {
  case get(key) {
    Some(value) -> int.parse(value)
    None -> Error(Nil)
  }
}

pub fn get_int_or(key: String, default: Int) -> Int {
  case get_int(key) {
    Ok(value) -> value
    Error(_) -> default
  }
}

pub fn get_bool(key: String) -> Result(Bool, Nil) {
  case get(key) {
    Some(value) -> {
      let lower = string.lowercase(value)
      case lower {
        "true" | "1" | "yes" | "on" -> Ok(True)
        "false" | "0" | "no" | "off" -> Ok(False)
        _ -> Error(Nil)
      }
    }
    None -> Error(Nil)
  }
}

pub fn get_bool_or(key: String, default: Bool) -> Bool {
  case get_bool(key) {
    Ok(value) -> value
    Error(_) -> default
  }
}

/// check if env variable is set
pub fn has(key: String) -> Bool {
  case get(key) {
    Some(_) -> True
    None -> False
  }
}

/// require an environment variable, (will cause an error if not set)
pub fn require(key: String) -> Result(String, String) {
  case get(key) {
    Some(value) -> Ok(value)
    None -> Error("Required environment variable not set: " <> key)
  }
}

/// used to get a specific variable from a loaded env_vars dict (for manual loading)
pub fn dict_get(env_vars: Dict(String, String), key: String) -> Option(String) {
  case dict.get(env_vars, key) {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}

/// get a variable with default from a dict
pub fn dict_get_or(
  env_vars: Dict(String, String),
  key: String,
  default: String,
) -> String {
  case dict_get(env_vars, key) {
    Some(value) -> value
    None -> default
  }
}

@external(erlang, "dotenv_ffi", "get_env")
@external(javascript, "./dotenv_ffi.mjs", "getEnv")
fn get_system_env(key: String) -> Result(String, Nil)

@external(erlang, "dotenv_ffi", "set_env")
@external(javascript, "./dotenv_ffi.mjs", "setEnv")
fn set_system_env(key: String, value: String) -> Bool
