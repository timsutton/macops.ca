---
title: "Quick Fix for Git Branch Naming Issues"
date: 2024-01-03
---

Today I learned that if you accidentally create a Git branch with a space in the name, you can still delete it using quotes:

```bash
git branch -D "branch name with spaces"
```

Much better than having to deal with escape characters!