[//]: # (title:markdown-editor)

# Welcome to markdown-editor

This markdown-editor is a 99% client-side javascript viewer and editor for markdown.

Why 1% missing. Because when you finished to edit your document you can upload it directly to your web server.

---

## How to compile ?

Just clone the repository and run the **compile.sh** provided script file.

```
git clone git@github.com:cyd01/markdown-editor.git
cd markdown-editor
./compile.sh
```

It produces a new file **install.php**. Just upload it on your web site and call it.

---

## How does it work ?

- To switch from page viewer to page editor, just **double-click**
- To protect the page with password **ALT+p**
- To save the page press **ALT+o**
- To swtich between embedded style sheet press **ATL+t**
- To switch back to the viewer press **escape key**

---

## Special features

Use Markdown comments to define special page settings:

| Comment                             | Description           |
| ----------------------------------- | --------------------- |
| `[//]: # (title:This is the title)` | Define the page title |
| `[//]: # (style:css/united)`        | Define the page style |
