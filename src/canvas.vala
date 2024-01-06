using GL;
using ValaGL.Core;

namespace ValaGL {
    
    private const float[] cube_vertices = {
        // front
        -1, -1,  1,
        1, -1,  1,
        1,  1,  1,
        -1,  1,  1,
        // back
        -1, -1, -1,
        1, -1, -1,
        1,  1, -1,
        -1,  1, -1,
    };
    
    private const float[] cube_colors = {
        // front colors
        1, 0, 0,
        0, 1, 0,
        0, 0, 1,
        1, 1, 1,
        // back colors
        1, 0, 0,
        0, 1, 0,
        0, 0, 1,
        1, 1, 1,
    };
    
    private const ushort cube_elements[] = {
        // front
        0, 1, 2,
        2, 3, 0,
        // top
        1, 5, 6,
        6, 2, 1,
        // back
        7, 6, 5,
        5, 4, 7,
        // bottom
        4, 0, 3,
        3, 7, 4,
        // left
        4, 5, 1,
        1, 0, 4,
        // right
        3, 2, 6,
        6, 7, 3,
    };
    
    /**
     * The OpenGL canvas associated with the application main window.
     * 
     * This class is responsible for initializing the state of the OpenGL context
     * and managing resize and redraw events sent by the underlying SDL window.
     */
    public class Canvas : Object {
        private GLProgram gl_program;
        private VBO coord_vbo;
        private VBO color_vbo;
        private VAO vao;
        private IBO element_ibo;
        
        private Camera camera;
        private Mat4 model_matrix;
        
        private int unif_transform;
        private int attr_coord3d;
        private int attr_v_color;
        public ArcballCamera arc_camera = new ArcballCamera();
        
        public Vec3 eye;
        public Vec3 center;
        public Vec3 up;
        public int render_mode = -1;
        
        /**
         * Instantiates a new canvas object.
         * 
         * Assumes that the desired OpenGL context is already selected.
         * 
         * Initializes GLEW, global OpenGL state, and GPU programs that will be
         * used for rendering.
         */
        public Canvas() throws AppError {
            glEnable(GL_DEBUG_OUTPUT);
            glDebugMessageCallback(on_gl_error);
            
            // GL initialization comes here
            glClearColor(71.0f / 255, 95.0f / 255, 121.0f / 255, 1);
            glEnable(GL_MULTISAMPLE);
            glEnable(GL_DEPTH_TEST);
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            try {
                gl_program = new GLProgram(
                    "resource:///valagl/shaders/vertex.glsl",
                    "resource:///valagl/shaders/fragment.glsl"
                );
                
                unif_transform = gl_program.get_uniform_location("transform");
                attr_coord3d = gl_program.get_attrib_location("coord3d");
                attr_v_color = gl_program.get_attrib_location("v_color");
                
                vao = new VAO();
                
                coord_vbo = new VBO(cube_vertices);
                vao.register_vbo(coord_vbo, attr_coord3d, 3);
                
                color_vbo = new VBO(cube_colors);
                vao.register_vbo(color_vbo, attr_v_color, 3);
                
                element_ibo = new IBO(cube_elements);
            } catch (CoreError e) {
                throw new AppError.INIT(e.message);
            }
            
            camera = new Camera();
            eye = Vec3.from_data(0, 0, 1);
            center = Vec3.from_data(0, 0, -2);
            up = Vec3.from_data(0, 1, 0);
            update_camera();
        }
        
        public void update_camera() {
            camera.look_at(ref eye, ref center, ref up);
        }
        
        private void on_gl_error(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, string message) {
            stderr.printf("GL CALLBACK: %s type = 0x%x, severity = 0x%x, message = %s\n",
                ( type == GL_DEBUG_TYPE_ERROR ? "** GL ERROR **" : "" ),
                type, severity, message );
        }
        
        /**
         * Handler of the window resize event.
         * 
         * It is called for the first time when the SDL window is created and shown,
         * and then every time the display resolution changes.
         * 
         * Responsible for setting up the viewport size and perspective projection.
         * 
         * @param width The new window width
         * @param height The new window height
         */
        public void resize_gl(int width, int height) {
            glViewport(0, 0, width, height);
            //camera.set_ortho_projection(0, width, 0, height, -1, 1);
            camera.set_perspective_projection(70, (float) width / (float) height, 0.01f, 100f);
        }
        
        /**
         * Handler of the window repaint event.
         * 
         * It is called every time the window is created.
         * 
         * Responsible for drawing the OpenGL scene.
         */
        public void paint_gl() {
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            
            update_render_mode();
            
            // Compute current transformation matrix for the cube
            model_matrix = Mat4.identity();
            
            Vec3 translation = Vec3.from_data(0, 0, -4);
            GeometryUtil.translate(ref model_matrix, ref translation);
            
            GeometryUtil.rotate(ref model_matrix, arc_camera.angle, ref arc_camera.rotational_axis);
            
            // Activate our vertex and fragment shaders for the next drawing operations
            gl_program.make_current();
            
            // Apply camera before drawing the model
            camera.apply(unif_transform, ref model_matrix);
            
            glEnableVertexAttribArray(attr_coord3d);
            glEnableVertexAttribArray(attr_v_color);
            
            // Apply buffers
            vao.make_current();
            element_ibo.make_current();
            
            // Draw the cube
            glDrawElements(GL_TRIANGLES, cube_elements.length, GL_UNSIGNED_SHORT, null);
            glDisableVertexAttribArray(attr_coord3d);
            glDisableVertexAttribArray(attr_v_color);
        }
        
        private void update_render_mode() {
            switch (render_mode) {
                case 0:
                    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
                    glEnable(GL_DEPTH_TEST);
                    glEnable(GL_CULL_FACE);
                    render_mode = -1;
                    break;
                case 1:
                    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
                    glDisable(GL_DEPTH_TEST);
                    glDisable(GL_CULL_FACE);
                    render_mode = -1;
                    break;
                case 2:
                    glPolygonMode(GL_FRONT_AND_BACK, GL_POINT);
                    glDisable(GL_DEPTH_TEST);
                    glDisable(GL_CULL_FACE);
                    render_mode = -1;
                    break;
            }
        }
    }
    
    public struct Quaternion {
        public float cosine;
        public Vec3 axis;
    }
    
    public class ArcballCamera {
        public Vec3 position = Vec3.from_data(0, 0, -3);
        public Vec3 start_pos = Vec3.from_data(0, 0, 0);
        public Vec3 current_pos = Vec3.from_data(0, 0, 0);
        public Vec3 start_pos_unit_vector;
        public Vec3 current_pos_unit_vector;
        
        public Quaternion current_quaternion;
        public Quaternion last_quaternion = { 0, Vec3.from_data(1, 0, 0) };
        
        public float cos_value;
        public float cos_value_2;
        public float theta;
        public float angle = 180;
        public Vec3 rotational_axis = Vec3.from_data(1, 0, 0);
        public Vec3 rotational_axis_2;
        
        public void rotation() {
            start_pos_unit_vector = get_unit_vector(start_pos);
            current_pos_unit_vector = get_unit_vector(current_pos);
            current_quaternion.axis = start_pos.cross_product(ref current_pos);
            current_quaternion.axis = get_unit_vector(current_quaternion.axis);
            
            cos_value = dot_product(); //q0 is cosine of the angle here.
            if (cos_value > 1) cos_value = 1; // when dot product gives '1' as result, it doesn't equal to 1 actually. It equals to just like 1.00000000001 . 
            theta = (float) (Math.acos(cos_value) * 180 / 3.1416); //theta is the angle now.
            current_quaternion.cosine = (float) Math.cos((theta / 2) * 3.1416 / 180); //currentQuaternion.cosine is cos of half the angle now.

            current_quaternion.axis.x = (float) (current_quaternion.axis.x * Math.sin((theta / 2) * 3.1416 / 180));
            current_quaternion.axis.y = (float) (current_quaternion.axis.y * Math.sin((theta / 2) * 3.1416 / 180));
            current_quaternion.axis.z = (float) (current_quaternion.axis.z * Math.sin((theta / 2) * 3.1416 / 180));
            
            cos_value_2 = (current_quaternion.cosine * last_quaternion.cosine)
                                 - current_quaternion.axis.dot_product(ref last_quaternion.axis);
            
            
            Vec3 temporary_vector = current_quaternion.axis.cross_product(ref last_quaternion.axis);
            
            rotational_axis_2.x = (current_quaternion.cosine * last_quaternion.axis.x) + 
                                    (last_quaternion.cosine * current_quaternion.axis.x ) +
                                    temporary_vector.x;

            rotational_axis_2.y = (current_quaternion.cosine * last_quaternion.axis.y) + 
                                    (last_quaternion.cosine * current_quaternion.axis.y ) +
                                    temporary_vector.y;

            rotational_axis_2.z = (current_quaternion.cosine * last_quaternion.axis.z) + 
                                    (last_quaternion.cosine * current_quaternion.axis.z ) +
                                    temporary_vector.z;
            
            angle = (float) (Math.acos(cos_value_2) * 180 / 3.1416) * 2;

            rotational_axis.x = (float) (rotational_axis_2.x / Math.sin((angle / 2) * 3.1416 / 180));
            rotational_axis.y = (float) (rotational_axis_2.y / Math.sin((angle / 2) * 3.1416 / 180));
            rotational_axis.z = (float) (rotational_axis_2.z / Math.sin((angle / 2) * 3.1416 / 180));
        }
        
        public float dot_product() {
            return (start_pos_unit_vector.x * current_pos_unit_vector.x) + (start_pos_unit_vector.y * current_pos_unit_vector.y) + (start_pos_unit_vector.z * current_pos_unit_vector.z);
        }
        
        public void replace() {
            last_quaternion.cosine = cos_value_2;
            last_quaternion.axis = rotational_axis_2;
        }
        
        public float z_axis(float x, float y) {
            float z = 0; 
            if (Math.sqrt((x * x) + (y * y)) <= 1)
                z = (float) Math.sqrt((1 * 1) - (x * x) - (y * y)); 
            return z;
        }
        
        public Vec3 get_unit_vector(Vec3 vector) {
            float magnitude;
            Vec3 unit_vector = Vec3.from_data(0, 0, 0);
            
            magnitude = (vector.x * vector.x) + (vector.y * vector.y) + (vector.z * vector.z);
            magnitude = (float) Math.sqrt(magnitude);
            
            if (magnitude == 0) {
                unit_vector.x = 0;
                unit_vector.y = 0;
                unit_vector.z = 0;
            } else {
                unit_vector.x = vector.x / magnitude;
                unit_vector.y = vector.y / magnitude;
                unit_vector.z = vector.z / magnitude;
            }
            
            return unit_vector;
        }
    }
}
