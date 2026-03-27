{application, sift, [
    {vsn, "0.1.0"},
    {applications, [gleam_regexp,
                    gleam_stdlib,
                    gleeunit]},
    {description, "Schema validation for Gleam — constraints, error accumulation, and field paths"},
    {modules, [sift,
               sift@int,
               sift@option,
               sift@string,
               sift_test]},
    {registered, []}
]}.
