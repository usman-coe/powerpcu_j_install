declare module "*.exe" {
  const path: string;
  export default path;
}

declare module "*.txt" {
  const text: string;
  export default text;
}
