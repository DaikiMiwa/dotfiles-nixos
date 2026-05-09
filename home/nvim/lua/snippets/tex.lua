local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local i = ls.insert_node
local s = ls.snippet
local t = ls.text_node

return {
	s(
		"doc",
		fmt(
			[[
\documentclass[{}]{{{}}}
\usepackage{{amsmath,amssymb}}
\usepackage{{graphicx}}
\usepackage{{hyperref}}

\title{{{}}}
\author{{{}}}
\date{{\today}}

\begin{{document}}
\maketitle

{}

\end{{document}}
]],
			{
				i(1, "a4paper,11pt"),
				i(2, "ltjsarticle"),
				i(3, "Title"),
				i(4, "Author"),
				i(0),
			}
		)
	),

	s(
		"platexrc",
		fmt(
			[[
$latex = '{} -synctex=1 -interaction=nonstopmode -file-line-error %O %S';
$bibtex = '{} %O %B';
$dvipdf = 'dvipdfmx %O -o %D %S';
$pdf_mode = 3;
]],
			{
				i(1, "platex"),
				i(2, "pbibtex"),
			}
		)
	),
	s("lualatex", t("% !TEX program = lualatex")),
	s("pdflatex", t("% !TEX program = pdflatex")),
	s("platex", t("% !TEX program = platex")),
	s("uplatex", t("% !TEX program = uplatex")),
	s(
		"biblatex",
		fmt(
			[[
\usepackage[backend={},style={},sorting={}]{{biblatex}}
\addbibresource{{{}}}
]],
			{
				i(1, "biber"),
				i(2, "numeric"),
				i(3, "none"),
				i(4, "references.bib"),
			}
		)
	),
	s("printbib", t("\\printbibliography")),

	s(
		"fig",
		fmt(
			[[
\begin{{figure}}[{}]
  \centering
  \includegraphics[width={}\linewidth]{{{}}}
  \caption{{{}}}
  \label{{fig:{}}}
\end{{figure}}
]],
			{
				i(1, "tbp"),
				i(2, "0.8"),
				i(3, "path/to/image"),
				i(4, "Caption"),
				i(5, "label"),
			}
		)
	),

	s(
		"tbl",
		fmt(
			[[
\begin{{table}}[{}]
  \centering
  \caption{{{}}}
  \label{{tab:{}}}
  \begin{{tabular}}{{{}}}
    \hline
    {} \\
    \hline
    {} \\
    \hline
  \end{{tabular}}
\end{{table}}
]],
			{
				i(1, "tbp"),
				i(2, "Caption"),
				i(3, "label"),
				i(4, "ll"),
				i(5, "Header 1 & Header 2"),
				i(0, "Value 1 & Value 2"),
			}
		)
	),

	s("eq", fmt("\\begin{{equation}}\n  {}\n\\end{{equation}}", { i(0) })),
	s("al", fmt("\\begin{{align}}\n  {}\n\\end{{align}}", { i(0) })),
	s("ca", fmt("\\begin{{cases}}\n  {}\n\\end{{cases}}", { i(0) })),
	s("pmat", fmt("\\begin{{pmatrix}}\n  {}\n\\end{{pmatrix}}", { i(0) })),
	s("bmat", fmt("\\begin{{bmatrix}}\n  {}\n\\end{{bmatrix}}", { i(0) })),
	s("fr", fmt("\\frac{{{}}}{{{}}}", { i(1), i(2) })),
	s("it", fmt("\\begin{{itemize}}\n  \\item {}\n\\end{{itemize}}", { i(0) })),
	s("en", fmt("\\begin{{enumerate}}\n  \\item {}\n\\end{{enumerate}}", { i(0) })),
	s("abs", fmt("\\begin{{abstract}}\n  {}\n\\end{{abstract}}", { i(0) })),
	s("thm", fmt("\\begin{{theorem}}[{}]\n  {}\n\\end{{theorem}}", { i(1, "Title"), i(0) })),
	s("lem", fmt("\\begin{{lemma}}[{}]\n  {}\n\\end{{lemma}}", { i(1, "Title"), i(0) })),
	s("defn", fmt("\\begin{{definition}}[{}]\n  {}\n\\end{{definition}}", { i(1, "Title"), i(0) })),
	s("prf", fmt("\\begin{{proof}}\n  {}\n\\end{{proof}}", { i(0) })),
	s("sec", fmt("\\section{{{}}}", { i(0, "Section") })),
	s("ssec", fmt("\\subsection{{{}}}", { i(0, "Subsection") })),
	s("sssec", fmt("\\subsubsection{{{}}}", { i(0, "Subsubsection") })),
	s("pkg", fmt("\\usepackage{{{}}}", { i(0, "package") })),
	s("ref", fmt("\\ref{{{}:{}}}", { i(1, "fig"), i(0, "label") })),
	s("cref", fmt("\\cref{{{}:{}}}", { i(1, "fig"), i(0, "label") })),
	s("cite", fmt("\\cite{{{}}}", { i(0, "key") })),
	s("lbl", fmt("\\label{{{}:{}}}", { i(1, "sec"), i(0, "label") })),
}
