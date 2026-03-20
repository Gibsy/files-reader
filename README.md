# usage:

```bash
nasm -f win32 main.asm -o main.obj
```
```bash
golink /entry Start /console main.obj kernel32.dll
```

# then drag-and-drop files on exe
