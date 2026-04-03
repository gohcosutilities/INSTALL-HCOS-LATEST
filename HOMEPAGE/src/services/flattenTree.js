export const flattenTree = (tree) => {
    const result = [];
    const traverse = (node) => {
      result.push(node);
      if (node.children) {
        node.children.forEach(traverse);
      }
    };
    tree.forEach(traverse);
    return result;
  };