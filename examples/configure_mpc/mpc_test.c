#include "mpc.h"

#include <stdio.h>

int main(int argc, char** argv) {
  mpc_t x;
  mpc_t y;
  mpc_t z;
  mpc_init2(x, 64);
  mpc_init2(y, 64);
  mpc_init2(z, 64);
  mpc_set_ui_ui(x, 2, 3, MPC_RNDNN);
  mpc_set_ui_ui(y, 3, 2, MPC_RNDNN);
  mpc_add(z, x, y, MPC_RNDNN);
  mpc_out_str(stdout, 10, 0, x, MPC_RNDNN);
  fprintf(stdout, " + ");
  mpc_out_str(stdout, 10, 0, y, MPC_RNDNN);
  fprintf(stdout, " = ");
  mpc_out_str(stdout, 10, 0, z, MPC_RNDNN);
  fprintf(stdout, "\n");
  fflush(stdout);
  mpc_clear(x);
  mpc_clear(y);
  mpc_clear(z);
  return 0;
}
