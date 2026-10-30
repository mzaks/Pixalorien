// For a single-core link (tools/static_cc.py): devices/text.c calls
// omp_in_parallel() through a weak declaration, expecting the OpenMP
// runtime to be there or not at all — which Mach-O's linker will not
// leave undefined. Without --parallel the true answer is always 0.
int omp_in_parallel(void) { return 0; }
