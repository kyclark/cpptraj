#!/bin/bash

. ../MasterTest.sh

CleanFiles charmm.in test.ala3.pdb.? test.ala3.pdb.10 first.ala3.crd \
           test.psf test.ala3.dcd second.ala3.crd strip.chamber.parm7 \
           run0.res_0.mol2 cpptraj.psf cpptraj.cor ala3.drude.mol2 \
           acemd.atoms.dat acemd.res.dat vmd8.atoms.dat vmd8.res.dat

TESTNAME='Charmm DCD tests'
Requires maxthreads 10

INPUT="-i charmm.in"
cat > charmm.in <<EOF
parm ala3.psf
trajin ala3.dcd 1 10
trajout test.ala3.pdb pdb multi chainid X
EOF
RunCpptraj "CHARMM PSF/DCD test"
DoTest test.ala3.pdb.save test.ala3.pdb.1

# Second test: Read in 10 frames of a dcd traj, write
# both an Amber coord and dcd traj. Then read the written
# dcd traj and convert to second amber traj. Compare the
# written amber trajs
cat > charmm.in <<EOF
parm ala3.psf
trajin ala3.dcd 1 10
trajout first.ala3.crd
trajout test.ala3.dcd dcd
EOF
RunCpptraj "CHARMM DCD Write, step 1."

cat > charmm.in <<EOF
parm ala3.psf
trajin test.ala3.dcd
trajout second.ala3.crd
EOF
RunCpptraj "CHARMM DCD Write, step 2."
DoTest first.ala3.crd second.ala3.crd

# Third test; psf -> psf
cat > charmm.in <<EOF
parm ala3.psf
parminfo
parmwrite out test.psf
EOF
#RunCpptraj "CHARMM PSF Write test."

# CHAMBER strip test
cat > charmm.in <<EOF
parm chamber.ala3.parm7
parmstrip :2-3
parmwrite out strip.chamber.parm7
quit
EOF
RunCpptraj "CHAMBER topology read/strip test."
DoTest strip.chamber.parm7.save strip.chamber.parm7 -I %VERSION

UNITNAME='Read CHARMM restart'
CheckFor maxthreads 1
if [ $? -eq 0 ] ; then
  cat > charmm.in <<EOF
parm ala3.psf
trajin run0.res_0
trajout run0.res_0.mol2
EOF
  RunCpptraj "$UNITNAME"
  DoTest run0.res_0.mol2.save run0.res_0.mol2
fi

UNITNAME='CHARMM PSF write'
cat > charmm.in <<EOF
parm ala3.psf
parmwrite out cpptraj.psf
EOF
RunCpptraj "$UNITNAME"
DoTest cpptraj.psf.save cpptraj.psf

UNITNAME='CHARMM COORdinates test'
CheckFor maxthreads 1
if [ $? -eq 0 ] ; then
  cat > charmm.in <<EOF
parm ala3.psf
trajin ala3.min.cor
trajout cpptraj.cor segid ALA3
EOF
  RunCpptraj "$UNITNAME"
  DoTest cpptraj.cor.save cpptraj.cor
fi

UNITNAME='CHARMM Drude PSF test'
CheckFor maxthreads 1
if [ $? -eq 0 ] ; then
  cat > charmm.in <<EOF
parm ala3.drude.psf
trajin ala3.drude.crd
trajout ala3.drude.mol2
EOF
  RunCpptraj "$UNITNAME"
  DoTest ala3.drude.mol2 ala3.drude.mol2.save
fi

# Atom lines with 8 columns come in two layouts; both must read correctly.
# CHARMM without the Constrained column (written e.g. by ACEMD):
#   AtomID SegID ResID ResName AtomName AtomType Charge Mass
UNITNAME='CHARMM PSF, 8 columns: SegID, no Constrained (ACEMD)'
cat > charmm.in <<EOF
parm acemd.psf
atominfo * out acemd.atoms.dat
resinfo * out acemd.res.dat
EOF
RunCpptraj "$UNITNAME"
DoTest acemd.atoms.dat.save acemd.atoms.dat
DoTest acemd.res.dat.save acemd.res.dat

# VMD-like, no SegID:
#   AtomID ResID ResName AtomName AtomType Charge Mass Constrained
UNITNAME='CHARMM PSF, 8 columns: no SegID, Constrained (VMD-like)'
cat > charmm.in <<EOF
parm vmd8.psf
atominfo * out vmd8.atoms.dat
resinfo * out vmd8.res.dat
EOF
RunCpptraj "$UNITNAME"
DoTest vmd8.atoms.dat.save vmd8.atoms.dat
DoTest vmd8.res.dat.save vmd8.res.dat

EndTest

exit 0
