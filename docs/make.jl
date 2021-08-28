using GARComp
using Documenter

DocMeta.setdocmeta!(GARComp, :DocTestSetup, :(using GARComp); recursive=true)

makedocs(;
    modules=[GARComp],
    authors="pvpisistratus <pvpisistratus@gmail.com> and contributors",
    repo="https://github.com/pvpisistratus/GARComp.jl/blob/{commit}{path}#{line}",
    sitename="GARComp.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://pvpisistratus.github.io/GARComp.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/pvpisistratus/GARComp.jl",
)
