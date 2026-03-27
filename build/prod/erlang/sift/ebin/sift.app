{application, sift, [
    {vsn, "0.1.0"},
    {applications, [gleam_regexp,
                    gleam_stdlib]},
    {description, "Schema validation for Gleam — constraints, error accumulation, and field paths"},
    {modules, [sift,
               sift@@main,
               sift@float,
               sift@int,
               sift@list,
               sift@option,
               sift@string]},
    {registered, []}
]}.
