blueprints = custom_target(
    'blueprints',
    
    input: files(
        'ui/window.blp',
    ),
    output: '.',
    command: [ find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@' ],
)

# Include shaders in executable
valagl_resources = gnome.compile_resources(
    'valagl-resources',
    'valagl.gresource.xml',
    dependencies: blueprints
)