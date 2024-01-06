using GL;

namespace ValaGL.Core {
    
    /**
     * Static helper class for stock geometry calculations and matrix transformations.
     */
    public class GeometryUtil : Object {
        
        private GeometryUtil() {}
        
        /**
         * Converts the given angle from degrees to radians.
         * 
         * @param deg Angle in radians
         * @return Angle in degrees
         */
        public static float deg_to_rad(float deg) {
            return (float) (deg * Math.PI / 180f);
        }
        
        /**
         * Converts the given angle from radians to degrees.
         * 
         * @param rad Angle in degrees
         * @return Angle in radians
         */
        public static float rad_to_deg(float rad) {
            return (float) (rad / Math.PI * 180f);
        }
        
        /**
         * Multiples the given matrix by a matrix that specifies a translation
         * by the given vector. The matrix is modified in-place.
         * 
         * For more information, refer to the ``glTranslatef`` legacy OpenGL function.
         * 
         * @param matrix The matrix to transform
         * @param translation The translation vector
         */
        public static void translate(ref Mat4 matrix, ref Vec3 translation) {
            var tmp = Mat4.from_data(
                1, 0, 0, translation.x,
                0, 1, 0, translation.y,
                0, 0, 1, translation.z,
                0, 0, 0, 1
            );
            
            matrix.mul_mat(ref tmp);
        }
        
        /**
         * Multiples the given matrix by a matrix that specifies a scale operation
         * by the given factors in the x, y and z directions.
         * The matrix is modified in-place.
         * 
         * For more information, refer to the ``glScalef`` legacy OpenGL function.
         * 
         * @param matrix The matrix to transform
         * @param scale_factors The scale factor vector
         */
        public static void scale(ref Mat4 matrix, ref Vec3 scale_factors) {
            var tmp = Mat4.from_data(
                scale_factors.x, 0, 0, 0,
                0, scale_factors.y, 0, 0,
                0, 0, scale_factors.z, 0,
                0, 0, 0, 1
            );
            
            matrix.mul_mat(ref tmp);
        }
        
        
        /**
         * Multiples the given matrix by a matrix that specifies a rotation around
         * the given axis by the given angle. The matrix is modified in-place.
         * 
         * Be careful with these rotations. Unlike quaternion-based transformations,
         * they may incur gimbal lock.
         * 
         * For more information, refer to the ``glRotatef`` legacy OpenGL function.
         * 
         * @param matrix The matrix to transform
         * @param angle_deg The rotation angle in degrees
         * @param axis The rotation axis
         */
        public static void rotate(ref Mat4 matrix, float angle_deg, ref Vec3 axis) {
            Vec3 axis_normalized = axis;
            axis_normalized.normalize();
            
            float angle_rad = deg_to_rad(angle_deg);
            
            // M = uuT + (cos a) (1 - uuT) + (sin a) S
            Mat3 tmp1 = Mat3.from_vec_mul(ref axis_normalized, ref axis_normalized);
            Mat3 tmp2 = Mat3.identity();
            tmp2.sub(ref tmp1);
            tmp2.mul(Math.cosf(angle_rad));
            tmp1.add(ref tmp2);
            
            Mat3 s = Mat3.from_data(
                0, -axis_normalized.z, axis_normalized.y,
                axis_normalized.z, 0, -axis_normalized.x,
                -axis_normalized.y, axis_normalized.x, 0
            );
            s.mul(Math.sinf(angle_rad));
            tmp1.add(ref s);
            
            var tmp = Mat4.expand(ref tmp1);
            matrix.mul_mat(ref tmp);
        }
    }
}
