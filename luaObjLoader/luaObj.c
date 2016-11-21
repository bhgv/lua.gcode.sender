
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>


#define TINYOBJ_LOADER_C_IMPLEMENTATION
#include "tinyobj_loader_c.h"

#include <float.h>
#include <limits.h>
#include <math.h>

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <unistd.h>




char *filename;

//#undef lua_newtable
//#define lua_newtable(l) lua_createtable(l, 1, 1)

#define lua_seti lua_rawseti

void type2lua(lua_State *L, const char* t){
                lua_pushstring(L, t);
                lua_setfield(L, -2, "type");
}

void pt2lua(lua_State *L, double x, double y, double z, float *bmin, float *bmax){
                //lua_newtable(L);
                lua_createtable(L, 0, 4);
//                type2lua(L, "pointer");
    
                lua_pushnumber(L, (lua_Number)x);
                lua_setfield(L, -2, "x");
    
                lua_pushnumber(L, (lua_Number)y);
                lua_setfield(L, -2, "y");
                
                lua_pushnumber(L, (lua_Number)z);
                lua_setfield(L, -2, "z");
                
                if(x < bmin[0]) bmin[0] = x;
                if(y < bmin[1]) bmin[1] = y;
                if(z < bmin[2]) bmin[2] = z;
                
                if(x > bmax[0]) bmax[0] = x;
                if(y > bmax[1]) bmax[1] = y;
                if(z > bmax[2]) bmax[2] = z;
}

void fc2lua(lua_State *L, int p1, int p2, int p3){
                //lua_newtable(L);
                lua_createtable(L, 0, 4);
//                type2lua(L, "face");
                
                lua_pushinteger(L, p1 + 1);
                lua_setfield(L, -2, "p1");
                
                lua_pushinteger(L, p2 + 1);
                lua_setfield(L, -2, "p2");
                
                lua_pushinteger(L, p3 + 1);
                lua_setfield(L, -2, "p3");
}




static void CalcNormal(float N[3], float v0[3], float v1[3], float v2[3]) {
  float v10[3];
  float v20[3];
  float len2;

  v10[0] = v1[0] - v0[0];
  v10[1] = v1[1] - v0[1];
  v10[2] = v1[2] - v0[2];

  v20[0] = v2[0] - v0[0];
  v20[1] = v2[1] - v0[1];
  v20[2] = v2[2] - v0[2];

  N[0] = v20[1] * v10[2] - v20[2] * v10[1];
  N[1] = v20[2] * v10[0] - v20[0] * v10[2];
  N[2] = v20[0] * v10[1] - v20[1] * v10[0];

  len2 = N[0] * N[0] + N[1] * N[1] + N[2] * N[2];
  if (len2 > 0.0f) {
    float len = (float)sqrt((double)len2);

    N[0] /= len;
    N[1] /= len;
  }
}


static const char* mmap_file(size_t* len, const char* filename) {
  FILE* f;
  long file_size;
  struct stat sb;
  char* p;
  int fd;

  (*len) = 0;

  f = fopen(filename, "r");
  fseek(f, 0, SEEK_END);
  file_size = ftell(f);
  fclose(f);

  fd = open(filename, O_RDONLY);
  if (fd == -1) {
    perror("open");
    return NULL;
  }

  if (fstat(fd, &sb) == -1) {
    perror("fstat");
    return NULL;
  }

  if (!S_ISREG(sb.st_mode)) {
    fprintf(stderr, "%s is not a file\n", "lineitem.tbl");
    return NULL;
  }

  p = (char*)mmap(0, (size_t)file_size, PROT_READ, MAP_SHARED, fd, 0);

  if (p == MAP_FAILED) {
    perror("mmap");
    return NULL;
  }

  if (close(fd) == -1) {
    perror("close");
    return NULL;
  }

  (*len) = (size_t)file_size;

  return p;
}


static const char* get_file_data(size_t* len, const char* filename) {
  const char* ext = strrchr(filename, '.');

  size_t data_len = 0;
  const char* data = NULL;

  if (strcmp(ext, ".gz") == 0) {
    assert(0); /* todo */

  } else {
    data = mmap_file(&data_len, filename);
  }

  (*len) = data_len;
  return data;
}




static int do_parse_obj(lua_State *L) {
  float bmin[3]; 
  float bmax[3];
  
  tinyobj_attrib_t attrib;
  tinyobj_shape_t* shapes = NULL;
  size_t num_shapes;
  tinyobj_material_t* materials = NULL;
  size_t num_materials;

  size_t data_len = 0;
  
  char *filename = (char*)lua_tostring(L, -1);
//  printf("%s\n", filename);
  
  lua_settop(L, 0);
//  lua_gc(L, LUA_GCCOLLECT, 0);
  lua_gc(L, LUA_GCSTOP, 0);
  
  const char* data = get_file_data(&data_len, filename);
  if (data == NULL) {
    lua_gc(L, LUA_GCRESTART, 0);
    return 0;
  }
//  printf("filesize: %d\n", (int)data_len);

  {
    unsigned int flags = TINYOBJ_FLAG_TRIANGULATE;
    int ret = tinyobj_parse_obj(&attrib, &shapes, &num_shapes, &materials,
                                &num_materials, data, data_len, flags);
    if (ret != TINYOBJ_SUCCESS) {
      return 0;
    }

    /**
    printf("# of shapes    = %d\n", (int)num_shapes);
    printf("# of materiasl = %d\n", (int)num_materials);
    **/

    lua_newtable(L);
    type2lua(L, "top");


    /**
    {
      int i;
      for (i = 0; i < num_shapes; i++) {
        printf("shape[%d] name = %s\n", i, shapes[i].name);
      }
    }
    **/
  }

  bmin[0] = bmin[1] = bmin[2] = FLT_MAX;
  bmax[0] = bmax[1] = bmax[2] = -FLT_MAX;

  {
    size_t face_offset = 0;
    size_t i;

    /* Assume triangulated face. */
    size_t num_triangles = attrib.num_face_num_verts;
//    size_t stride = 9; /* 9 = pos(3float), normal(3float), color(3float) */

    lua_newtable(L);
    type2lua(L, "verts");
    for(i = 0; i < attrib.num_vertices; i++){
        pt2lua(L, attrib.vertices[3*i + 0], attrib.vertices[3*i + 1], attrib.vertices[3*i + 2], bmin, bmax);
        lua_seti(L, -2, i+1);
    }
    lua_setfield(L, -2, "verts");
    
    lua_newtable(L);
    type2lua(L, "faces");

    for(i = 0; i < attrib.num_face_num_verts; i++){
      assert(attrib.face_num_verts[i] % 3 == 0); /* assume all triangle faces. */
//      printf("num_verts %d\n", attrib.face_num_verts[i]);

        tinyobj_vertex_index_t idx0 = attrib.faces[face_offset + 0];
        tinyobj_vertex_index_t idx1 = attrib.faces[face_offset + 1];
        tinyobj_vertex_index_t idx2 = attrib.faces[face_offset + 2];

        fc2lua(L, idx0.v_idx, idx1.v_idx, idx2.v_idx);
        lua_seti(L, -2, i+1);
        
        face_offset += (size_t)attrib.face_num_verts[i];
    }
    lua_setfield(L, -2, "faces");
    
    
    /**/
    face_offset = 0;
    
    lua_newtable(L);
    type2lua(L, "normals");
    
    for(i = 0; i < attrib.num_face_num_verts; i++){
        size_t k;
        float v[3][3];
        float n[3][3];
        //float c[3];
        //float len2;

        assert(attrib.face_num_verts[i] % 3 == 0); /* assume all triangle faces. */
//        printf("num_norms %d\n", attrib.face_num_verts[i]);

        tinyobj_vertex_index_t idx0 = attrib.faces[face_offset + 0];
        tinyobj_vertex_index_t idx1 = attrib.faces[face_offset + 1];
        tinyobj_vertex_index_t idx2 = attrib.faces[face_offset + 2];

        for (k = 0; k < 3; k++) {
          int f0 = idx0.v_idx;
          int f1 = idx1.v_idx;
          int f2 = idx2.v_idx;
          assert(f0 >= 0);
          assert(f1 >= 0);
          assert(f2 >= 0);

          v[0][k] = attrib.vertices[3 * (size_t)f0 + k];
          v[1][k] = attrib.vertices[3 * (size_t)f1 + k];
          v[2][k] = attrib.vertices[3 * (size_t)f2 + k];
        }

        if (attrib.num_normals > 0) {
          int f0 = idx0.vn_idx;
          int f1 = idx1.vn_idx;
          int f2 = idx2.vn_idx;
          if (f0 >= 0 && f1 >= 0 && f2 >= 0) {
            assert(f0 < (int)attrib.num_normals);
            assert(f1 < (int)attrib.num_normals);
            assert(f2 < (int)attrib.num_normals);
            for (k = 0; k < 3; k++) {
              n[0][k] = attrib.normals[3 * (size_t)f0 + k];
              n[1][k] = attrib.normals[3 * (size_t)f1 + k];
              n[2][k] = attrib.normals[3 * (size_t)f2 + k];
            }
          } else { /* normal index is not defined for this face */
            /* compute geometric normal */
            CalcNormal(n[0], v[0], v[1], v[2]);
            n[1][0] = n[0][0];
            n[1][1] = n[0][1];
            n[1][2] = n[0][2];
            n[2][0] = n[0][0];
            n[2][1] = n[0][1];
            n[2][2] = n[0][2];
          }
        } else {
          /* compute geometric normal */
          CalcNormal(n[0], v[0], v[1], v[2]);
          n[1][0] = n[0][0];
          n[1][1] = n[0][1];
          n[1][2] = n[0][2];
          n[2][0] = n[0][0];
          n[2][1] = n[0][1];
          n[2][2] = n[0][2];
        }
        
        //lua
        
        
        face_offset += (size_t)attrib.face_num_verts[i];
    }
    lua_setfield(L, -2, "normals");
    /**/
    
    /**/
    pt2lua(L, bmin[0], bmin[1], bmin[2], bmin, bmax);
    lua_setfield(L, -2, "min");
    
    pt2lua(L, bmax[0], bmax[1], bmax[2], bmin, bmax);
    lua_setfield(L, -2, "max");
    /**/
    
    //      face_offset += (size_t)attrib.face_num_verts[i];
    
  }

//  printf("bmin = %f, %f, %f\n", (double)bmin[0], (double)bmin[1],
//         (double)bmin[2]);
//  printf("bmax = %f, %f, %f\n", (double)bmax[0], (double)bmax[1],
//         (double)bmax[2]);

  tinyobj_attrib_free(&attrib);
  tinyobj_shapes_free(shapes, num_shapes);
  tinyobj_materials_free(materials, num_materials);
    
  lua_gc(L, LUA_GCRESTART, 0);
//  lua_gc(L, LUA_GCCOLLECT, 0);

  return 1;
}




static const struct luaL_Reg lua_Methods[] = {
    {"do_parse", do_parse_obj},
//    {"__gc", delete_parser},
     
    {NULL, NULL}        /* Sentinel */
};



LUALIB_API int luaopen_luaObj(lua_State *L){
    printf("luaObj\n");

    /* Create gcodeparser metatable */
    luaL_newmetatable(L, "luaObj");
    /* Set metatable functions */
    const struct luaL_Reg *funcs = (const struct luaL_Reg *)lua_Methods;
    for (; funcs->name != NULL; funcs++) {
        lua_pushcclosure(L, funcs->func, 0);
        lua_setfield(L, -2, funcs->name);
    }

    /* Set metatable properties */
    lua_pushstring(L, "protected metatable");
    lua_setfield(L, -2, "__metatable");

    /* Create {__call = lua_serial_new, __metatable = "protected metatable", version = ...} table */
    lua_newtable(L);
    lua_pushcclosure(L, do_parse_obj, 0); 
    lua_setfield(L, -2, "__call");
    lua_pushstring(L, "protected metatable");
    lua_setfield(L, -2, "__metatable");
    /* Set it as the metatable for the periphery.Serial metatable */
    lua_setmetatable(L, -2);

    return 1;
 }



