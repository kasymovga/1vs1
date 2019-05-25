// non-solid brush entities:
void spawnfunc_func_illusionary()       { model_init      (SOLID_NOT);} // Q1 name (WARNING: MISPREDICTED)
void spawnfunc_func_clientillusionary() { model_client_init(SOLID_NOT);} // brush entity
void spawnfunc_func_static()            { model_init      (SOLID_NOT);} // DEPRECATED old alias name from some other game

// solid brush entities
void spawnfunc_func_wall()              { model_init      (SOLID_BSP);} // Q1 name
void spawnfunc_func_clientwall()        { model_client_init(SOLID_BSP);} // brush entity (WARNING: MISPREDICTED)
