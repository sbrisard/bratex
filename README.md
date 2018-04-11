# bratex
Emacs package for manipulation of brackets in LaTeX mode

If you dislike the `\left` and `\right` macros in LaTeX, you are not alone!
Quoting from the manual of the [amsmath](https://ctan.org/pkg/amsmath) package
(see section 4.14.1):

> The automatic delimiter sizing done by \left and \right has two limitations:
> First, it is applied mechanically to produce delimiters large enough to
> encompass the largest contained item, and second, the range of sizes is not
> even approximately continuous but has fairly large quantum jumps.

You might prefer manual sizing through the size modifiers: `\big`, `\Big`,
`\bigg` and `\Bigg`, or even better (this requires `amsmath`): `\bigl...\bigr`,
`\Bigl...\Bigr`, `\biggl...\biggr` and `\Biggl...\Biggr`. But then, resizing
becomes painful: you need to move to the opening delimiter, change its size
modifier, then move to the closing delimiter, and do the same.

Introducing `bratex`, that defines a functions to automatically cycle through
size delimiters.
