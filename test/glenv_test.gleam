import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import glenv
import simplifile

pub fn main() {
  gleeunit.main()
}

fn create_test_env_file(path: String, content: String) -> Nil {
  let _ = simplifile.write(path, content)
  Nil
}

fn cleanup_test_file(path: String) -> Nil {
  let _ = simplifile.delete(path)
  Nil
}

pub fn parse_empty_line_test() {
  let _ =
    glenv.load_with_config(glenv.Config(
      path: "test_empty.env",
      override: False,
      ignore_missing: False,
    ))

  create_test_env_file("test_empty.env", "")

  case
    glenv.load_with_config(glenv.Config(
      path: "test_empty.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      dict.size(env_vars)
      |> should.equal(0)
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_empty.env")
}

pub fn parse_comment_lines_test() {
  let content = "# This is a comment\n# Another comment\nKEY=value"
  create_test_env_file("test_comments.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_comments.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      dict.size(env_vars)
      |> should.equal(1)

      glenv.dict_get(env_vars, "KEY")
      |> should.equal(Some("value"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_comments.env")
}

pub fn parse_basic_key_value_test() {
  let content = "KEY1=value1\nKEY2=value2"
  create_test_env_file("test_basic.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_basic.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      dict.size(env_vars)
      |> should.equal(2)

      glenv.dict_get(env_vars, "KEY1")
      |> should.equal(Some("value1"))

      glenv.dict_get(env_vars, "KEY2")
      |> should.equal(Some("value2"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_basic.env")
}

pub fn parse_quoted_values_test() {
  let content = "KEY1=\"quoted value\"\nKEY2='single quoted'\nKEY3=unquoted"
  create_test_env_file("test_quotes.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_quotes.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      glenv.dict_get(env_vars, "KEY1")
      |> should.equal(Some("quoted value"))

      glenv.dict_get(env_vars, "KEY2")
      |> should.equal(Some("single quoted"))

      glenv.dict_get(env_vars, "KEY3")
      |> should.equal(Some("unquoted"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_quotes.env")
}

pub fn parse_whitespace_handling_test() {
  let content = "  KEY1  =  value1  \n\tKEY2\t=\tvalue2\t"
  create_test_env_file("test_whitespace.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_whitespace.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      glenv.dict_get(env_vars, "KEY1")
      |> should.equal(Some("value1"))

      glenv.dict_get(env_vars, "KEY2")
      |> should.equal(Some("value2"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_whitespace.env")
}

pub fn parse_error_empty_key_test() {
  let content = "=value"
  create_test_env_file("test_empty_key.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_empty_key.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(_) -> should.fail()
    Error(glenv.ParseError(msg, line)) -> {
      string.contains(msg, "Empty variable name")
      |> should.be_true()
      line |> should.equal(1)
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_empty_key.env")
}

pub fn parse_error_missing_equals_test() {
  let content = "KEY_WITHOUT_EQUALS"
  create_test_env_file("test_no_equals.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_no_equals.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(_) -> should.fail()
    Error(glenv.ParseError(msg, line)) -> {
      string.contains(msg, "missing '='")
      |> should.be_true()
      line |> should.equal(1)
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_no_equals.env")
}

pub fn load_default_test() {
  let content = "TEST_KEY=test_value"
  create_test_env_file(".env", content)

  case glenv.load() {
    Ok(env_vars) -> {
      glenv.dict_get(env_vars, "TEST_KEY")
      |> should.equal(Some("test_value"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file(".env")
}

pub fn load_missing_file_ignore_test() {
  case
    glenv.load_with_config(glenv.Config(
      path: "nonexistent.env",
      override: False,
      ignore_missing: True,
    ))
  {
    Ok(env_vars) -> {
      dict.size(env_vars)
      |> should.equal(0)
    }
    Error(_) -> should.fail()
  }
}

pub fn load_missing_file_error_test() {
  case
    glenv.load_with_config(glenv.Config(
      path: "nonexistent.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(_) -> should.fail()
    Error(glenv.FileNotFound(path)) -> {
      path |> should.equal("nonexistent.env")
    }
    Error(_) -> should.fail()
  }
}

pub fn config_default_test() {
  let config = glenv.default_config()
  config.path |> should.equal(".env")
  config.override |> should.equal(False)
  config.ignore_missing |> should.equal(True)
}

pub fn dict_get_test() {
  let env_vars =
    dict.new()
    |> dict.insert("KEY1", "value1")
    |> dict.insert("KEY2", "value2")

  glenv.dict_get(env_vars, "KEY1")
  |> should.equal(Some("value1"))

  glenv.dict_get(env_vars, "NONEXISTENT")
  |> should.equal(None)
}

pub fn dict_get_or_test() {
  let env_vars =
    dict.new()
    |> dict.insert("KEY1", "value1")

  glenv.dict_get_or(env_vars, "KEY1", "default")
  |> should.equal("value1")

  glenv.dict_get_or(env_vars, "NONEXISTENT", "default")
  |> should.equal("default")
}

pub fn get_system_env_test() {
  case glenv.get("PATH") {
    Some(_) -> should.be_true(True)
    None -> should.fail()
  }
}

pub fn get_or_test() {
  glenv.get_or("VERY_UNLIKELY_ENV_VAR_NAME_12345", "default_value")
  |> should.equal("default_value")
}

pub fn get_int_valid_test() {
  let content = "NUMBER=42"
  create_test_env_file("test_int.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_int.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      case glenv.dict_get(env_vars, "NUMBER") {
        Some(value) -> {
          case int.parse(value) {
            Ok(num) -> num |> should.equal(42)
            Error(_) -> should.fail()
          }
        }
        None -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_int.env")
}

pub fn get_int_or_test() {
  glenv.get_int_or("NONEXISTENT_INT_VAR", 100)
  |> should.equal(100)
}

pub fn get_bool_true_values_test() {
  let test_cases = [
    #("true", True),
    #("TRUE", True),
    #("1", True),
    #("yes", True),
    #("YES", True),
    #("on", True),
    #("ON", True),
  ]

  list.each(test_cases, fn(test_case) {
    let #(value, expected) = test_case
    let content = "BOOL_VAR=" <> value
    create_test_env_file("test_bool.env", content)

    case
      glenv.load_with_config(glenv.Config(
        path: "test_bool.env",
        override: False,
        ignore_missing: False,
      ))
    {
      Ok(env_vars) -> {
        case glenv.dict_get(env_vars, "BOOL_VAR") {
          Some(val) -> {
            let lower = string.lowercase(val)
            case lower {
              "true" | "1" | "yes" | "on" -> expected |> should.equal(True)
              "false" | "0" | "no" | "off" -> expected |> should.equal(False)
              _ -> should.fail()
            }
          }
          None -> should.fail()
        }
      }
      Error(_) -> should.fail()
    }

    cleanup_test_file("test_bool.env")
  })
}

pub fn get_bool_false_values_test() {
  let test_cases = [
    #("false", False),
    #("FALSE", False),
    #("0", False),
    #("no", False),
    #("NO", False),
    #("off", False),
    #("OFF", False),
  ]

  list.each(test_cases, fn(c) {
    let #(value, expected) = c
    let content = "BOOL_VAR=" <> value
    create_test_env_file("test_bool.env", content)

    case
      glenv.load_with_config(glenv.Config(
        path: "test_bool.env",
        override: False,
        ignore_missing: False,
      ))
    {
      Ok(env_vars) -> {
        case glenv.dict_get(env_vars, "BOOL_VAR") {
          Some(val) -> {
            let lower = string.lowercase(val)
            case lower {
              "true" | "1" | "yes" | "on" -> expected |> should.equal(True)
              "false" | "0" | "no" | "off" -> expected |> should.equal(False)
              _ -> should.fail()
            }
          }
          None -> should.fail()
        }
      }
      Error(_) -> should.fail()
    }

    cleanup_test_file("test_bool.env")
  })
}

pub fn get_bool_or_test() {
  glenv.get_bool_or("NONEXISTENT_BOOL_VAR", True)
  |> should.equal(True)

  glenv.get_bool_or("NONEXISTENT_BOOL_VAR", False)
  |> should.equal(False)
}

pub fn has_test() {
  glenv.has("PATH")
  |> should.be_true()

  glenv.has("VERY_UNLIKELY_ENV_VAR_NAME_12345")
  |> should.be_false()
}

pub fn require_existing_test() {
  case glenv.require("PATH") {
    Ok(_) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

pub fn require_missing_test() {
  case glenv.require("NONEXISTENT_REQUIRED_VAR") {
    Ok(_) -> should.fail()
    Error(msg) -> {
      string.contains(msg, "Required environment variable not set")
      |> should.be_true()
      string.contains(msg, "NONEXISTENT_REQUIRED_VAR")
      |> should.be_true()
    }
  }
}

pub fn complex_env_file_test() {
  let content =
    "
# Database configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp

# API settings
API_KEY=\"secret-key-with-special-chars!@#\"
API_TIMEOUT=30

# Feature flags
ENABLE_FEATURE_X=true
ENABLE_FEATURE_Y=false

# Empty values
EMPTY_VALUE=

# Quoted empty
QUOTED_EMPTY=\"\"

# Single quoted
SINGLE_QUOTED='single value'
"

  create_test_env_file("test_complex.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_complex.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      glenv.dict_get(env_vars, "DB_HOST")
      |> should.equal(Some("localhost"))

      glenv.dict_get(env_vars, "DB_PORT")
      |> should.equal(Some("5432"))

      glenv.dict_get(env_vars, "API_KEY")
      |> should.equal(Some("secret-key-with-special-chars!@#"))

      glenv.dict_get(env_vars, "ENABLE_FEATURE_X")
      |> should.equal(Some("true"))

      glenv.dict_get(env_vars, "ENABLE_FEATURE_Y")
      |> should.equal(Some("false"))

      glenv.dict_get(env_vars, "EMPTY_VALUE")
      |> should.equal(Some(""))

      glenv.dict_get(env_vars, "QUOTED_EMPTY")
      |> should.equal(Some(""))

      glenv.dict_get(env_vars, "SINGLE_QUOTED")
      |> should.equal(Some("single value"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_complex.env")
}

pub fn parse_error_line_numbers_test() {
  let content = "VALID_KEY=value\nINVALID_LINE_NO_EQUALS\nANOTHER_VALID=value"
  create_test_env_file("test_error_line.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_error_line.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(_) -> should.fail()
    Error(glenv.ParseError(_, line_number)) -> {
      line_number |> should.equal(2)
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_error_line.env")
}

pub fn clean_value_double_quotes_test() {
  let content = "KEY=\"value with spaces\""
  create_test_env_file("test_clean.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_clean.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      glenv.dict_get(env_vars, "KEY")
      |> should.equal(Some("value with spaces"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_clean.env")
}

pub fn clean_value_single_quotes_test() {
  let content = "KEY='value with spaces'"
  create_test_env_file("test_clean_single.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_clean_single.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      glenv.dict_get(env_vars, "KEY")
      |> should.equal(Some("value with spaces"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_clean_single.env")
}

pub fn clean_value_no_quotes_test() {
  let content = "KEY=value_no_quotes"
  create_test_env_file("test_no_quotes.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_no_quotes.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      glenv.dict_get(env_vars, "KEY")
      |> should.equal(Some("value_no_quotes"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_no_quotes.env")
}

pub fn clean_value_mismatched_quotes_test() {
  let content = "KEY=\"value'"
  create_test_env_file("test_mismatch.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_mismatch.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      glenv.dict_get(env_vars, "KEY")
      |> should.equal(Some("\"value'"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_mismatch.env")
}

pub fn init_test() {
  let content = "TEST_INIT_VAR=init_value"
  create_test_env_file(".env", content)

  case glenv.init() {
    Ok(Nil) -> {
      should.be_true(True)
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file(".env")
}

pub fn special_characters_test() {
  let content =
    "
SPECIAL_CHARS=\"value with !@#$%^&*()\"
URL=\"https://example.com/path?param=value&other=123\"
PATH_VALUE=\"/home/user/my folder/file.txt\"
JSON_LIKE='{\"key\":\"value\",\"number\":123}'
"

  create_test_env_file("test_special.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_special.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      glenv.dict_get(env_vars, "SPECIAL_CHARS")
      |> should.equal(Some("value with !@#$%^&*()"))

      glenv.dict_get(env_vars, "URL")
      |> should.equal(Some("https://example.com/path?param=value&other=123"))

      glenv.dict_get(env_vars, "PATH_VALUE")
      |> should.equal(Some("/home/user/my folder/file.txt"))

      glenv.dict_get(env_vars, "JSON_LIKE")
      |> should.equal(Some("{\"key\":\"value\",\"number\":123}"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_special.env")
}

pub fn mixed_line_types_test() {
  let content =
    "# Configuration file
VALID_KEY=value

# Another comment
ANOTHER_KEY=\"quoted value\"

# This line has an error
=empty_key_error

FINAL_KEY=final_value"

  create_test_env_file("test_mixed.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_mixed.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(_) -> should.fail()
    Error(glenv.ParseError(_, line_number)) -> {
      line_number |> should.equal(8)
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_mixed.env")
}

pub fn empty_value_test() {
  let content = "EMPTY_KEY="
  create_test_env_file("test_empty_val.env", content)

  case
    glenv.load_with_config(glenv.Config(
      path: "test_empty_val.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      glenv.dict_get(env_vars, "EMPTY_KEY")
      |> should.equal(Some(""))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_empty_val.env")
}
