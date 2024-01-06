using GL;

namespace ValaGL.Core {
    
    /**
     * Encapsulation of an OpenGL vertex array object.
     * 
     * The underlying OpenGL vertex array is destroyed when this object is finally unreferenced.
     */
    public class VAO : Object {
        private uint id;
        
        /**
         * Creates a vertex array object.
         */
        public VAO() throws CoreError {
            uint id_array[1];
            glGenVertexArrays(1, id_array);
            id = id_array[0];
            
            if (id == 0) {
                throw new CoreError.VBO_INIT("Cannot allocate vertex array object");
            }
        }
        
        /**
         * Registers a VBO binding to the given shader attribute in this VAO.
         */
        public void register_vbo(VBO vbo, int attribute, int stride) {
            make_current();
            vbo.make_current();
            glVertexAttribPointer(attribute, stride, GL_FLOAT, (GLboolean) GL_FALSE, 0, null);
        }
        
        /**
         * Makes this VAO current for future drawing operations in the OpenGL context.
         */
        public void make_current() {
            glBindVertexArray(id);
        }
        
        ~VAO() {
            if (id != 0) {
                uint[] id_array = { id };
                glDeleteVertexArrays(1, id_array);
            }
        }
    }
}
