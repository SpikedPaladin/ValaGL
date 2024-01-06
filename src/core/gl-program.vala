using GL;

namespace ValaGL.Core {
    
    /**
     * Encapsulation of an OpenGL GPU program, containing one vertex shader and one fragment shader.
     */
    public class GLProgram : Object {
        private uint vertex_shader = 0;
        private uint fragment_shader = 0;
        private uint prog_id = 0;
        
        /**
         * Instantiates a new OpenGL program object, reading the vertex and fragment shaders from files.
         * 
         * @param vertex_shader_file The file to read the vertex shader from
         * @param fragment_shader_file The file to read the fragment shader from
         */
        public GLProgram(string vertex_shader_file, string fragment_shader_file) throws CoreError {
            vertex_shader = create_shader_from_file(GL_VERTEX_SHADER, vertex_shader_file);
            fragment_shader = create_shader_from_file(GL_FRAGMENT_SHADER, fragment_shader_file);
            
            prog_id = glCreateProgram();
            
            if (prog_id == 0)
                throw new CoreError.SHADER_INIT("Cannot allocate GL program ID");
            
            glAttachShader(prog_id, vertex_shader);
            glAttachShader(prog_id, fragment_shader);
            glLinkProgram(prog_id);

            int[] link_ok = { GL_FALSE };
            glGetProgramiv(prog_id, GL_LINK_STATUS, link_ok);
            
            if (link_ok[0] != GL_TRUE)
                throw new CoreError.SHADER_INIT("Cannot link GL program");
        }
        
        ~GLProgram() {
            if (vertex_shader != 0)
                glDeleteShader(vertex_shader);
            
            if (fragment_shader != 0)
                glDeleteShader(fragment_shader);
            
            if (prog_id != 0)
                glDeleteProgram(prog_id);
        }
        
        /**
         * Gets the ID for the shader ``attribute`` variable with the specified name.
         * 
         * @return The attribute ID
         */
        public int get_attrib_location(string name) {
            assert(prog_id != 0);
            return glGetAttribLocation(prog_id, name);
        }
        
        /**
         * Gets the ID for the shader ``uniform`` variable with the specified name.
         * 
         * @return The uniform ID
         */
        public int get_uniform_location(string name) {
            assert(prog_id != 0);
            return glGetUniformLocation(prog_id, name);
        }
        
        /**
         * Makes this OpenGL program current in the current OpenGL context, applying it to future drawing operations.
         */
        public void make_current() {
            assert(prog_id != 0);
            glUseProgram(prog_id);
        }
        
        private static uint create_shader_from_file(uint shader_type, string file_path) throws CoreError {
            try {
                uint8[] file_contents;
                
                var file = file_path.has_prefix("resource://") ? File.new_for_uri(file_path) : File.new_for_path(file_path);
                
                file.load_contents(null, out file_contents, null);
                return create_shader_from_string(shader_type, (string) file_contents);
            } catch (Error e) {
                throw new CoreError.SHADER_INIT(e.message);
            }
        }
        
        private static uint create_shader_from_string(uint shader_type, string source) throws CoreError {
            var shader = glCreateShader(shader_type);
            
            if (shader == 0)
                throw new CoreError.SHADER_INIT("Cannot allocate shader ID");
            
            string[] sourceArray = { source, null };
            glShaderSource(shader, 1, sourceArray, null);
            glCompileShader(shader);
            
            int[] compile_ok = { GL_FALSE };
            glGetShaderiv(shader, GL_COMPILE_STATUS, compile_ok);
            
            if (compile_ok[0] == GL_TRUE)
                return shader;
            
            // Otherwise, there is an error.
            glDeleteShader(shader);
            
            if (shader_type == GL_VERTEX_SHADER)
                throw new CoreError.SHADER_INIT("Error compiling vertex shader");
            else
                throw new CoreError.SHADER_INIT("Error compiling fragment shader");
        }
    }
}
