namespace ValaGL {
    
    // Code from https://www.songho.ca/opengl/gl_sphere.html
    public class Sphere : Object3D {
        float radius;
        int sectorCount; // longitude, # of slices
        int stackCount; // latitude, # of stacks
        bool smooth;
        int upAxis; // +X=1, +Y=2, +z=3 (default)
        public float[] normals;
        public float[] texCoords;
        public ushort[] lineIndices;

        // interleaved
        float[] interleavedVertices;
        
        public Sphere(float radius, int sectors, int stacks, bool smooth, int up) {
            this.radius = radius;
            this.sectorCount = sectors;
            this.stackCount = stacks;
            this.smooth = smooth;
            this.upAxis = up;
            
            if (smooth)
                buildVerticesSmooth();
            else
                build_vertices_flat();
            
            colors = normals;
        }
        
        struct Vertex {
            public float x;
            public float y;
            public float z;
            public float s;
            public float t;
        }
        
        private void clear_arrays() {
            vertices = {};
            normals = {};
            texCoords = {};
            indices = {};
            lineIndices = {};
        }
        
        public void buildVerticesSmooth() {
            float PI = (float) Math.PI;

            // clear memory of prev arrays
            clear_arrays();

            float x, y, z, xy;                              // vertex position
            float nx, ny, nz, lengthInv = 1.0f / radius;    // normal
            float s, t;                                     // texCoord

            float sectorStep = 2 * PI / sectorCount;
            float stackStep = PI / stackCount;
            float sectorAngle, stackAngle;

            for(int i = 0; i <= stackCount; ++i)
            {
                stackAngle = PI / 2 - i * stackStep;        // starting from pi/2 to -pi/2
                xy = radius * Math.cosf(stackAngle);             // r * cos(u)
                z = radius * Math.sinf(stackAngle);              // r * sin(u)

                // add (sectorCount+1) vertices per stack
                // the first and last vertices have same position and normal, but different tex coords
                for(int j = 0; j <= sectorCount; ++j) {
                    sectorAngle = j * sectorStep;           // starting from 0 to 2pi

                    // vertex position
                    x = xy * Math.cosf(sectorAngle);             // r * cos(u) * cos(v)
                    y = xy * Math.sinf(sectorAngle);             // r * cos(u) * sin(v)
                    add_vertex(x, y, z);

                    // normalized vertex normal
                    nx = x * lengthInv;
                    ny = y * lengthInv;
                    nz = z * lengthInv;
                    add_normal(nx, ny, nz);

                    // vertex tex coord between [0, 1]
                    s = (float)j / sectorCount;
                    t = (float)i / stackCount;
                    add_tex_coord(s, t);
                }
            }

            // indices
            //  k1--k1+1
            //  |  / |
            //  | /  |
            //  k2--k2+1
            int k1, k2;
            for (int i = 0; i < stackCount; ++i) {
                k1 = i * (sectorCount + 1);     // beginning of current stack
                k2 = k1 + sectorCount + 1;      // beginning of next stack

                for (int j = 0; j < sectorCount; ++j, ++k1, ++k2) {
                    // 2 triangles per sector excluding 1st and last stacks
                    if (i != 0)
                        add_indices((ushort) k1, (ushort) k2, (ushort) k1 + 1);   // k1---k2---k1+1

                    if (i != (stackCount - 1))
                        add_indices((ushort) k1 + 1, (ushort) k2, (ushort) k2 + 1); // k1+1---k2---k2+1

                    // vertical lines for all stacks
                    var temp = lineIndices.copy();
                    temp += (ushort) k1;
                    temp += (ushort) k2;
                    if (i != 0) { // horizontal lines except 1st stack
                        temp += (ushort) k1;
                        temp += (ushort) k1 + 1;
                    }
                    lineIndices = temp;
                }
            }

            // generate interleaved vertex array as well
            build_interleaved_vertices();

            // change up axis from Z-axis to the given
            if(upAxis != 3)
                change_up_axis(3, upAxis);
        }
        
        public void build_vertices_flat() {
            float PI = (float) Math.PI;
            Vertex[] tmp_vertices = {};
            float sectorStep = 2 * PI / sectorCount;
            float stackStep = PI / stackCount;
            float sectorAngle, stackAngle;
            
            for(int i = 0; i <= stackCount; ++i) {
                stackAngle = PI / 2 - i * stackStep;        // starting from pi/2 to -pi/2
                float xy = radius * Math.cosf(stackAngle);       // r * cos(u)
                float z = radius * Math.sinf(stackAngle);        // r * sin(u)

                // add (sectorCount+1) vertices per stack
                // the first and last vertices have same position and normal, but different tex coords
                for(int j = 0; j <= sectorCount; ++j) {
                    sectorAngle = j * sectorStep;           // starting from 0 to 2pi

                    Vertex vertex = Vertex();
                    vertex.x = xy * Math.cosf(sectorAngle);      // x = r * cos(u) * cos(v)
                    vertex.y = xy * Math.sinf(sectorAngle);      // y = r * cos(u) * sin(v)
                    vertex.z = z;                           // z = r * sin(u)
                    vertex.s = (float)j/sectorCount;        // s
                    vertex.t = (float)i/stackCount;         // t
                    tmp_vertices += vertex;
                }
            }
            
            // clear memory of prev arrays
            clear_arrays();
            
            Vertex v1, v2, v3, v4;                          // 4 vertex positions and tex coords
            float[] n = {};                           // 1 face normal

            int i, j, k, vi1, vi2;
            int index = 0;                                  // index for vertex
            for(i = 0; i < stackCount; ++i) {
                vi1 = i * (sectorCount + 1);                // index of tmpVertices
                vi2 = (i + 1) * (sectorCount + 1);

                for(j = 0; j < sectorCount; ++j, ++vi1, ++vi2) {
                    // get 4 vertices per sector
                    //  v1--v3
                    //  |    |
                    //  v2--v4
                    v1 = tmp_vertices[vi1];
                    v2 = tmp_vertices[vi2];
                    v3 = tmp_vertices[vi1 + 1];
                    v4 = tmp_vertices[vi2 + 1];

                    // if 1st stack and last stack, store only 1 triangle per sector
                    // otherwise, store 2 triangles (quad) per sector
                    if(i == 0) { // a triangle for first stack ==========================
                        // put a triangle
                        add_vertex(v1.x, v1.y, v1.z);
                        add_vertex(v2.x, v2.y, v2.z);
                        add_vertex(v4.x, v4.y, v4.z);

                        // put tex coords of triangle
                        add_tex_coord(v1.s, v1.t);
                        add_tex_coord(v2.s, v2.t);
                        add_tex_coord(v4.s, v4.t);

                        // put normal
                        n = compute_face_normal(v1.x,v1.y,v1.z, v2.x,v2.y,v2.z, v4.x,v4.y,v4.z);
                        for(k = 0; k < 3; ++k)  // same normals for 3 vertices
                            add_normal(n[0], n[1], n[2]);

                        // put indices of 1 triangle
                        add_indices((ushort) index, (ushort) index + 1, (ushort) index + 2);

                        // indices for line (first stack requires only vertical line)
                        var temp = lineIndices.copy();
                        temp += (ushort) index;
                        temp += (ushort) index + 1;
                        lineIndices = temp;

                        index += 3;     // for next
                    }
                    else if(i == (stackCount-1)) // a triangle for last stack =========
                    {
                        // put a triangle
                        add_vertex(v1.x, v1.y, v1.z);
                        add_vertex(v2.x, v2.y, v2.z);
                        add_vertex(v3.x, v3.y, v3.z);

                        // put tex coords of triangle
                        add_tex_coord(v1.s, v1.t);
                        add_tex_coord(v2.s, v2.t);
                        add_tex_coord(v3.s, v3.t);

                        // put normal
                        n = compute_face_normal(v1.x,v1.y,v1.z, v2.x,v2.y,v2.z, v3.x,v3.y,v3.z);
                        for(k = 0; k < 3; ++k)// same normals for 3 vertices
                            add_normal(n[0], n[1], n[2]);

                        // put indices of 1 triangle
                        add_indices((ushort) index, (ushort) index + 1, (ushort) index+ 2);

                        // indices for lines (last stack requires both vert/hori lines)
                        var temp = lineIndices.copy();
                        temp += (ushort) index;
                        temp += (ushort) index + 1;
                        temp += (ushort) index;
                        temp += (ushort) index + 2;
                        lineIndices = temp;

                        index += 3;     // for next
                    }
                    else // 2 triangles for others ====================================
                    {
                        // put quad vertices: v1-v2-v3-v4
                        add_vertex(v1.x, v1.y, v1.z);
                        add_vertex(v2.x, v2.y, v2.z);
                        add_vertex(v3.x, v3.y, v3.z);
                        add_vertex(v4.x, v4.y, v4.z);

                        // put tex coords of quad
                        add_tex_coord(v1.s, v1.t);
                        add_tex_coord(v2.s, v2.t);
                        add_tex_coord(v3.s, v3.t);
                        add_tex_coord(v4.s, v4.t);

                        // put normal
                        n = compute_face_normal(v1.x,v1.y,v1.z, v2.x,v2.y,v2.z, v3.x,v3.y,v3.z);
                        for(k = 0; k < 4; ++k)  // same normals for 4 vertices
                            add_normal(n[0], n[1], n[2]);

                        // put indices of quad (2 triangles)
                        add_indices((ushort) index, (ushort) index + 1, (ushort) index + 2);
                        add_indices((ushort) index + 2, (ushort) index + 1, (ushort) index + 3);

                        // indices for lines
                        var temp = lineIndices.copy();
                        temp += (ushort) index;
                        temp += (ushort) index + 1;
                        temp += (ushort) index;
                        temp += (ushort) index + 2;
                        lineIndices = temp;

                        index += 4;     // for next
                    }
                }
            }
            
            // generate interleaved vertex array as well
            build_interleaved_vertices();

            // change up axis from Z-axis to the given
            if(upAxis != 3)
                change_up_axis(3, upAxis);
        }
        
        public void build_interleaved_vertices() {
            interleavedVertices = {};

            int i, j;
            int count = vertices.length;
            for(i = 0, j = 0; i < count; i += 3, j += 2) {
                interleavedVertices += vertices[i];
                interleavedVertices += vertices[i+1];
                interleavedVertices += vertices[i+2];

                interleavedVertices += normals[i];
                interleavedVertices += normals[i+1];
                interleavedVertices += normals[i+2];

                interleavedVertices += texCoords[j];
                interleavedVertices += texCoords[j+1];
            }
        }
        
        public void change_up_axis(int from, int to) {
            // initial transform matrix cols
            float tx[] = {1.0f, 0.0f, 0.0f};    // x-axis (left)
            float ty[] = {0.0f, 1.0f, 0.0f};    // y-axis (up)
            float tz[] = {0.0f, 0.0f, 1.0f};    // z-axis (forward)

            // X -> Y
            if(from == 1 && to == 2)
            {
                tx[0] =  0.0f; tx[1] =  1.0f;
                ty[0] = -1.0f; ty[1] =  0.0f;
            }
            // X -> Z
            else if(from == 1 && to == 3)
            {
                tx[0] =  0.0f; tx[2] =  1.0f;
                tz[0] = -1.0f; tz[2] =  0.0f;
            }
            // Y -> X
            else if(from == 2 && to == 1)
            {
                tx[0] =  0.0f; tx[1] = -1.0f;
                ty[0] =  1.0f; ty[1] =  0.0f;
            }
            // Y -> Z
            else if(from == 2 && to == 3)
            {
                ty[1] =  0.0f; ty[2] =  1.0f;
                tz[1] = -1.0f; tz[2] =  0.0f;
            }
            //  Z -> X
            else if(from == 3 && to == 1)
            {
                tx[0] =  0.0f; tx[2] = -1.0f;
                tz[0] =  1.0f; tz[2] =  0.0f;
            }
            // Z -> Y
            else
            {
                ty[1] =  0.0f; ty[2] = -1.0f;
                tz[1] =  1.0f; tz[2] =  0.0f;
            }

            int i, j;
            int count = vertices.length;
            float vx, vy, vz;
            float nx, ny, nz;
            for(i = 0, j = 0; i < count; i += 3, j += 8) {
                // transform vertices
                vx = vertices[i];
                vy = vertices[i+1];
                vz = vertices[i+2];
                vertices[i]   = tx[0] * vx + ty[0] * vy + tz[0] * vz;   // x
                vertices[i+1] = tx[1] * vx + ty[1] * vy + tz[1] * vz;   // y
                vertices[i+2] = tx[2] * vx + ty[2] * vy + tz[2] * vz;   // z

                // transform normals
                nx = normals[i];
                ny = normals[i+1];
                nz = normals[i+2];
                normals[i]   = tx[0] * nx + ty[0] * ny + tz[0] * nz;   // nx
                normals[i+1] = tx[1] * nx + ty[1] * ny + tz[1] * nz;   // ny
                normals[i+2] = tx[2] * nx + ty[2] * ny + tz[2] * nz;   // nz

                // trnasform interleaved array
                interleavedVertices[j]   = vertices[i];
                interleavedVertices[j+1] = vertices[i+1];
                interleavedVertices[j+2] = vertices[i+2];
                interleavedVertices[j+3] = normals[i];
                interleavedVertices[j+4] = normals[i+1];
                interleavedVertices[j+5] = normals[i+2];
            }
        }
        
        public void add_vertex(float x, float y, float z) {
            float[] temp = vertices.copy();
            temp += x;
            temp += y;
            temp += z;
            
            vertices = temp;
        }
        
        public void add_normal(float nx, float ny, float nz) {
            float[] temp = normals.copy();
            temp += nx;
            temp += ny;
            temp += nz;
            
            normals = temp;
        }
        
        public void add_tex_coord(float s, float t) {
            float[] temp = texCoords.copy();
            temp += s;
            temp += t;
            
            texCoords = temp;
        }
        
        public void add_indices(ushort i1, ushort i2, ushort i3) {
            ushort[] temp = indices.copy();
            temp += i1;
            temp += i2;
            temp += i3;
            
            indices = temp;
        }
        
        public float[] compute_face_normal(
            float x1, float y1, float z1, // v1
            float x2, float y2, float z2, // v2
            float x3, float y3, float z3 // v3
        ) {
            const float EPSILON = 0.000001f;

            float[] normal = { 0, 0, 0 };     // default return value (0,0,0)
            float nx, ny, nz;

            // find 2 edge vectors: v1-v2, v1-v3
            float ex1 = x2 - x1;
            float ey1 = y2 - y1;
            float ez1 = z2 - z1;
            float ex2 = x3 - x1;
            float ey2 = y3 - y1;
            float ez2 = z3 - z1;

            // cross product: e1 x e2
            nx = ey1 * ez2 - ez1 * ey2;
            ny = ez1 * ex2 - ex1 * ez2;
            nz = ex1 * ey2 - ey1 * ex2;

            // normalize only if the length is > 0
            float length = Math.sqrtf(nx * nx + ny * ny + nz * nz);
            if(length > EPSILON) {
                // normalize
                float lengthInv = 1.0f / length;
                normal[0] = nx * lengthInv;
                normal[1] = ny * lengthInv;
                normal[2] = nz * lengthInv;
            }

            return normal;
        }
    }
}