using GL;

namespace ValaGL.Core {
    
    /**
     * Encapsulation of an OpenGL index buffer object.
     * 
     * The underlying OpenGL buffer is destroyed when this object is finally unreferenced.
     */
    public class IBO : Object {
        private uint id;
        
        /**
         * Creates an index buffer object.
         * 
         * @param data Array to bind to the OpenGL buffer
         */
        public IBO(ushort[] data) throws CoreError {
            uint id_array[1];
            glGenBuffers(1, id_array);
            id = id_array[0];
            
            if (id == 0)
                throw new CoreError.IBO_INIT("Cannot allocate index buffer object");
            
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, data.length * sizeof(GLushort), (GLvoid[]) data, GL_STATIC_DRAW);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        }
        
        /**
         * Makes this IBO current for future drawing operations in the OpenGL context.
         */
        public void make_current() {
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id);
        }
        
        ~IBO() {
            if (id != 0) {
                uint[] id_array = { id };
                glDeleteBuffers(1, id_array);
            }
        }
    }
}
