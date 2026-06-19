---
title: "Hugo Date Format Shortcodes"
date: 2024-01-09
---

Just discovered that Hugo has built-in date formatting shortcodes. Instead of writing out the full date format string, you can use:

```go
{{ .Date.Format "2006-01-02" }}  // Standard date format
{{ .Date.Format ":date_long" }}  // Long date format
{{ .Date.Format ":date_short" }} // Short date format
```

The weird "2006-01-02" reference date is because Go uses an example date (Jan 2, 2006 at 3:04:05PM MST) as its format template.