import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleamv
import gleeunit
import gleeunit/should
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
    gleamv.load_with_config(gleamv.Config(
      path: "test_empty.env",
      override: False,
      ignore_missing: False,
    ))

  create_test_env_file("test_empty.env", "")

  case
    gleamv.load_with_config(gleamv.Config(
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
  let content =
    "# This is a comment
# Another comment
KEY=value"
  create_test_env_file("test_comments.env", content)

  case
    gleamv.load_with_config(gleamv.Config(
      path: "test_comments.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      dict.size(env_vars)
      |> should.equal(1)

      gleamv.dict_get(env_vars, "KEY")
      |> should.equal(Ok("value"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_comments.env")
}

pub fn parse_basic_key_value_test() {
  let content =
    "KEY1=value1
KEY2=value2"
  create_test_env_file("test_basic.env", content)

  case
    gleamv.load_with_config(gleamv.Config(
      path: "test_basic.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      dict.size(env_vars)
      |> should.equal(2)

      gleamv.dict_get(env_vars, "KEY1")
      |> should.equal(Ok("value1"))

      gleamv.dict_get(env_vars, "KEY2")
      |> should.equal(Ok("value2"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_basic.env")
}

pub fn parse_quoted_values_test() {
  let content =
    "KEY1=\"quoted value\"
KEY2='single quoted'
KEY3=unquoted"
  create_test_env_file("test_quotes.env", content)

  case
    gleamv.load_with_config(gleamv.Config(
      path: "test_quotes.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      gleamv.dict_get(env_vars, "KEY1")
      |> should.equal(Ok("quoted value"))

      gleamv.dict_get(env_vars, "KEY2")
      |> should.equal(Ok("single quoted"))

      gleamv.dict_get(env_vars, "KEY3")
      |> should.equal(Ok("unquoted"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_quotes.env")
}

pub fn parse_whitespace_handling_test() {
  let content =
    "  KEY1  =  value1
	KEY2	=	value2	"
  create_test_env_file("test_whitespace.env", content)

  case
    gleamv.load_with_config(gleamv.Config(
      path: "test_whitespace.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      gleamv.dict_get(env_vars, "KEY1")
      |> should.equal(Ok("value1"))

      gleamv.dict_get(env_vars, "KEY2")
      |> should.equal(Ok("value2"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_whitespace.env")
}

pub fn parse_error_empty_key_test() {
  let content = "=value"
  create_test_env_file("test_empty_key.env", content)

  case
    gleamv.load_with_config(gleamv.Config(
      path: "test_empty_key.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(_) -> should.fail()
    Error(gleamv.ParseError(msg, line)) -> {
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
    gleamv.load_with_config(gleamv.Config(
      path: "test_no_equals.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(_) -> should.fail()
    Error(gleamv.ParseError(msg, line)) -> {
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

  case gleamv.load() {
    Ok(env_vars) -> {
      gleamv.dict_get(env_vars, "TEST_KEY")
      |> should.equal(Ok("test_value"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file(".env")
}

pub fn load_missing_file_ignore_test() {
  case
    gleamv.load_with_config(gleamv.Config(
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
    gleamv.load_with_config(gleamv.Config(
      path: "nonexistent.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(_) -> should.fail()
    Error(gleamv.FileNotFound(path)) -> {
      path |> should.equal("nonexistent.env")
    }
    Error(_) -> should.fail()
  }
}

pub fn config_default_test() {
  let config = gleamv.default_config()
  config.path |> should.equal(".env")
  config.override |> should.equal(False)
  config.ignore_missing |> should.equal(True)
}

pub fn dict_get_test() {
  let env_vars =
    dict.new()
    |> dict.insert("KEY1", "value1")
    |> dict.insert("KEY2", "value2")

  gleamv.dict_get(env_vars, "KEY1")
  |> should.equal(Ok("value1"))

  case gleamv.dict_get(env_vars, "NONEXISTENT") {
    Ok(_) -> should.fail()
    Error(gleamv.KeyError(_)) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

pub fn dict_get_or_test() {
  let env_vars =
    dict.new()
    |> dict.insert("KEY1", "value1")

  gleamv.dict_get_or(env_vars, "KEY1", "default")
  |> should.equal("value1")

  gleamv.dict_get_or(env_vars, "NONEXISTENT", "default")
  |> should.equal("default")
}

pub fn get_system_env_test() {
  case gleamv.get("PATH") {
    Some(_) -> should.be_true(True)
    None -> should.fail()
  }
}

pub fn get_or_test() {
  gleamv.get_or("VERY_UNLIKELY_ENV_VAR_NAME_12345", "default_value")
  |> should.equal("default_value")
}

pub fn get_int_valid_test() {
  let content = "NUMBER=42"
  create_test_env_file("test_int.env", content)

  case
    gleamv.load_with_config(gleamv.Config(
      path: "test_int.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      case gleamv.dict_get_int(env_vars, "NUMBER") {
        Ok(num) -> num |> should.equal(42)
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_int.env")
}

pub fn get_int_or_test() {
  gleamv.get_int_or("NONEXISTENT_INT_VAR", 100)
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
      gleamv.load_with_config(gleamv.Config(
        path: "test_bool.env",
        override: False,
        ignore_missing: False,
      ))
    {
      Ok(env_vars) -> {
        case gleamv.dict_get_bool(env_vars, "BOOL_VAR") {
          Ok(val) -> val |> should.equal(expected)
          Error(_) -> should.fail()
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
      gleamv.load_with_config(gleamv.Config(
        path: "test_bool.env",
        override: False,
        ignore_missing: False,
      ))
    {
      Ok(env_vars) -> {
        case gleamv.dict_get_bool(env_vars, "BOOL_VAR") {
          Ok(val) -> val |> should.equal(expected)
          Error(_) -> should.fail()
        }
      }
      Error(_) -> should.fail()
    }

    cleanup_test_file("test_bool.env")
  })
}

pub fn get_bool_or_test() {
  gleamv.get_bool_or("NONEXISTENT_BOOL_VAR", True)
  |> should.equal(True)

  gleamv.get_bool_or("NONEXISTENT_BOOL_VAR", False)
  |> should.equal(False)
}

pub fn has_test() {
  gleamv.has("PATH")
  |> should.be_true()

  gleamv.has("VERY_UNLIKELY_ENV_VAR_NAME_12345")
  |> should.be_false()
}

pub fn require_existing_test() {
  case gleamv.require("PATH") {
    Ok(_) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

pub fn require_missing_test() {
  case gleamv.require("NONEXISTENT_REQUIRED_VAR") {
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
    gleamv.load_with_config(gleamv.Config(
      path: "test_complex.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      gleamv.dict_get(env_vars, "DB_HOST")
      |> should.equal(Ok("localhost"))

      gleamv.dict_get(env_vars, "DB_PORT")
      |> should.equal(Ok("5432"))

      gleamv.dict_get(env_vars, "API_KEY")
      |> should.equal(Ok("secret-key-with-special-chars!@#"))

      gleamv.dict_get(env_vars, "ENABLE_FEATURE_X")
      |> should.equal(Ok("true"))

      gleamv.dict_get(env_vars, "ENABLE_FEATURE_Y")
      |> should.equal(Ok("false"))

      gleamv.dict_get(env_vars, "EMPTY_VALUE")
      |> should.equal(Ok(""))

      gleamv.dict_get(env_vars, "QUOTED_EMPTY")
      |> should.equal(Ok(""))

      gleamv.dict_get(env_vars, "SINGLE_QUOTED")
      |> should.equal(Ok("single value"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_complex.env")
}

pub fn parse_error_line_numbers_test() {
  let content =
    "VALID_KEY=value
INVALID_LINE_NO_EQUALS
ANOTHER_VALID=value"
  create_test_env_file("test_error_line.env", content)

  case
    gleamv.load_with_config(gleamv.Config(
      path: "test_error_line.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(_) -> should.fail()
    Error(gleamv.ParseError(_, line_number)) -> {
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
    gleamv.load_with_config(gleamv.Config(
      path: "test_clean.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      gleamv.dict_get(env_vars, "KEY")
      |> should.equal(Ok("value with spaces"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_clean.env")
}

pub fn clean_value_single_quotes_test() {
  let content = "KEY='value with spaces'"
  create_test_env_file("test_clean_single.env", content)

  case
    gleamv.load_with_config(gleamv.Config(
      path: "test_clean_single.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      gleamv.dict_get(env_vars, "KEY")
      |> should.equal(Ok("value with spaces"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_clean_single.env")
}

pub fn clean_value_no_quotes_test() {
  let content = "KEY=value_no_quotes"
  create_test_env_file("test_no_quotes.env", content)

  case
    gleamv.load_with_config(gleamv.Config(
      path: "test_no_quotes.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      gleamv.dict_get(env_vars, "KEY")
      |> should.equal(Ok("value_no_quotes"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_no_quotes.env")
}

pub fn clean_value_mismatched_quotes_test() {
  let content = "KEY=\"value'\""
  create_test_env_file("test_mismatch.env", content)

  case
    gleamv.load_with_config(gleamv.Config(
      path: "test_mismatch.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      gleamv.dict_get(env_vars, "KEY")
      |> should.equal(Ok("value'"))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_mismatch.env")
}

pub fn init_test() {
  let content = "TEST_INIT_VAR=init_value"
  create_test_env_file(".env", content)

  case gleamv.init() {
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
    gleamv.load_with_config(gleamv.Config(
      path: "test_special.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      gleamv.dict_get(env_vars, "SPECIAL_CHARS")
      |> should.equal(Ok("value with !@#$%^&*()"))

      gleamv.dict_get(env_vars, "URL")
      |> should.equal(Ok("https://example.com/path?param=value&other=123"))

      gleamv.dict_get(env_vars, "PATH_VALUE")
      |> should.equal(Ok("/home/user/my folder/file.txt"))

      gleamv.dict_get(env_vars, "JSON_LIKE")
      |> should.equal(Ok("{\"key\":\"value\",\"number\":123}"))
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
    gleamv.load_with_config(gleamv.Config(
      path: "test_mixed.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(_) -> should.fail()
    Error(gleamv.ParseError(_, line_number)) -> {
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
    gleamv.load_with_config(gleamv.Config(
      path: "test_empty_val.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      gleamv.dict_get(env_vars, "EMPTY_KEY")
      |> should.equal(Ok(""))
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_empty_val.env")
}

pub fn get_list_test() {
  create_test_env_file("test_list.env", "LIST_KEY=a,b,c")
  let assert Ok(Nil) =
    gleamv.init_with_config(gleamv.Config(
      "test_list.env",
      override: True,
      ignore_missing: False,
    ))

  gleamv.get_list("LIST_KEY")
  |> should.equal(Ok(["a", "b", "c"]))

  cleanup_test_file("test_list.env")
}

pub fn get_list_or_test() {
  create_test_env_file("test_list_or.env", "LIST_KEY=a,b,c")
  let assert Ok(Nil) =
    gleamv.init_with_config(gleamv.Config(
      "test_list_or.env",
      override: True,
      ignore_missing: False,
    ))

  gleamv.get_list_or("LIST_KEY", ["d", "e", "f"])
  |> should.equal(["a", "b", "c"])

  gleamv.get_list_or("NONEXISTENT_LIST", ["d", "e", "f"])
  |> should.equal(["d", "e", "f"])

  cleanup_test_file("test_list_or.env")
}

pub fn get_float_test() {
  create_test_env_file("test_float.env", "FLOAT_KEY=3.14")
  let assert Ok(Nil) =
    gleamv.init_with_config(gleamv.Config(
      "test_float.env",
      override: True,
      ignore_missing: False,
    ))

  gleamv.get_float("FLOAT_KEY")
  |> should.equal(Ok(3.14))

  cleanup_test_file("test_float.env")
}

pub fn get_float_or_test() {
  create_test_env_file("test_float_or.env", "FLOAT_KEY=3.14")
  let assert Ok(Nil) =
    gleamv.init_with_config(gleamv.Config(
      "test_float_or.env",
      override: True,
      ignore_missing: False,
    ))

  gleamv.get_float_or("FLOAT_KEY", 2.71)
  |> should.equal(3.14)

  gleamv.get_float_or("NONEXISTENT_FLOAT", 2.71)
  |> should.equal(2.71)

  cleanup_test_file("test_float_or.env")
}

pub fn dict_get_list_test() {
  let content = "LIST_KEY=a,b,c"
  create_test_env_file("test_dict_list.env", content)

  let assert Ok(env_vars) =
    gleamv.load_with_config(gleamv.Config(
      path: "test_dict_list.env",
      override: False,
      ignore_missing: False,
    ))

  gleamv.dict_get_list(env_vars, "LIST_KEY")
  |> should.equal(Ok(["a", "b", "c"]))

  cleanup_test_file("test_dict_list.env")
}

pub fn dict_get_list_or_test() {
  let content = "LIST_KEY=a,b,c"
  create_test_env_file("test_dict_list_or.env", content)

  let assert Ok(env_vars) =
    gleamv.load_with_config(gleamv.Config(
      path: "test_dict_list_or.env",
      override: False,
      ignore_missing: False,
    ))

  gleamv.dict_get_list_or(env_vars, "LIST_KEY", ["d", "e", "f"])
  |> should.equal(["a", "b", "c"])

  gleamv.dict_get_list_or(env_vars, "NONEXISTENT_LIST", ["d", "e", "f"])
  |> should.equal(["d", "e", "f"])

  cleanup_test_file("test_dict_list_or.env")
}

pub fn dict_get_float_test() {
  let content = "FLOAT_KEY=3.14"
  create_test_env_file("test_dict_float.env", content)

  let assert Ok(env_vars) =
    gleamv.load_with_config(gleamv.Config(
      path: "test_dict_float.env",
      override: False,
      ignore_missing: False,
    ))

  gleamv.dict_get_float(env_vars, "FLOAT_KEY")
  |> should.equal(Ok(3.14))

  cleanup_test_file("test_dict_float.env")
}

pub fn dict_get_float_or_test() {
  let content = "FLOAT_KEY=3.14"
  create_test_env_file("test_dict_float_or.env", content)

  let assert Ok(env_vars) =
    gleamv.load_with_config(gleamv.Config(
      path: "test_dict_float_or.env",
      override: False,
      ignore_missing: False,
    ))

  gleamv.dict_get_float_or(env_vars, "FLOAT_KEY", 2.71)
  |> should.equal(3.14)

  gleamv.dict_get_float_or(env_vars, "NONEXISTENT_FLOAT", 2.71)
  |> should.equal(2.71)

  cleanup_test_file("test_dict_float_or.env")
}

// purposefully do a failure on a type to make sure the error messages are clear
pub fn get_int_invalid_test() {
  let content = "NUMBER=not_an_int"
  create_test_env_file("test_invalid_int.env", content)

  case
    gleamv.load_with_config(gleamv.Config(
      path: "test_invalid_int.env",
      override: False,
      ignore_missing: False,
    ))
  {
    Ok(env_vars) -> {
      case gleamv.dict_get_int(env_vars, "NUMBER") {
        Ok(_) -> should.fail()
        Error(msg) -> {
          string.contains(
            gleamv.err_str(msg),
            "Invalid integer for key: NUMBER",
          )
          |> should.be_true()
        }
      }
    }
    Error(_) -> should.fail()
  }

  cleanup_test_file("test_invalid_int.env")
}
