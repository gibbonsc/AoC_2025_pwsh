# Advent of Code 2025 – PowerShell 7 Solutions

This repository contains my PowerShell 7 (pwsh) solutions for Advent of Code 2025:

[https://adventofcode.com/2025](https://adventofcode.com/2025)

I earned twenty of the 24 possible stars during the competition between 7-Dec (when I started) and 24-Dec (Christmas Eve). I kept struggling after it ended, and finally achieved all 24 stars on New Year's Eve.

## Scripts

- `01-1advent.ps1` → Day 1 Part 1
- `01-2advent.ps1` → Day 1 Part 2
- and so forth.
  
## Example input files

- `01-example.txt` → Same as the example from the [Day 1 challenge instructions](https://adventofcode.com/2025/day/1).

and so forth. For some challenges I crafted a few more examples for testing, such as:

- `09-1example2.txt` → Day 9, Part 1 second example input
- `09-1example2.ps1` → script to generate that file's contents

Challenge instructions and my actual competition input files are **not** included, because the creators specifically [asked](https://adventofcode.com/2025/about) that we not copy nor share those. Please refer to the [Advent of Code](https://adventofcode.com/) web site to compete and get official input data files of your very own.

## How to run

Rename *your* input file to prefix it with the two-digit day, such as `01-input.txt`. Then put it in the same folder as the script, launch PowerShell, and execute the script:

```console
pwsh ./01-1advent.ps1
```

I usually "dot-sourced" them from a PowerShell interactive prompt, because Visual Studio Code's "Run" triangle button automatically does that with a PowerShell Extension terminal:

```powershell
. ./01-2advent.ps1
```

which was nice because then I could use VS Code's debugger to step through code, and also use that terminal to continue manipulating functions and global variables during or after script executions.

## Detailed challenge experiences

coming soon
