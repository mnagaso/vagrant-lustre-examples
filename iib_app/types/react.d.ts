declare module "react" {
  export const Fragment: any;
  export function useState<S>(initialState: S | (() => S)): [S, (newState: S | ((prevState: S) => S)) => void];
  const React: any;
  export default React;
}

declare namespace JSX {
  type Element = any;
  interface IntrinsicElements {
    [elemName: string]: any;
  }
}

declare module "react/jsx-runtime" {
  const content: any;
  export default content;
}
