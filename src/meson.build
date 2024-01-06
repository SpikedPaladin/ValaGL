valagl_deps = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gio-2.0'),
    dependency('gtk4'),
    dependency('libadwaita-1'),
    dependency('gl')
]

valagl_sources = files(
    'app.vala',
    'app-error.vala',
    'canvas.vala',
    'main.vala',
    
    'ui/main-window.vala',
    
    'core/camera.vala',
    'core/core-error.vala',
    'core/geometry-util.vala',
    'core/gl-program.vala',
    'core/ibo.vala',
    'core/matrix-math.vala',
    'core/vao.vala',
    'core/vbo.vala',
    
    'core/objects/cube.vala',
    'core/objects/object-3d.vala',
    'core/objects/sphere.vala'
)

executable(
    'valagl',
    
    valagl_resources,
    valagl_sources,
    vala_args: [ '--target-glib=2.58', '--gresourcesdir=data/' ],
    dependencies: valagl_deps,
    link_args : ['-lepoxy', '-lm' ],
    install: true,
)
