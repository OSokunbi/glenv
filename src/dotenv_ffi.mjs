export function getEnv(key) {
  const value = process.env[key];
  return value !== undefined ? { tag: "Ok", value } : { tag: "Error", error: null };
}

export function setEnv(key, value) {
  process.env[key] = value;
  return true;
}
