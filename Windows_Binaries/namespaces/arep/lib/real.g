#F Functions for decomposing matrices over the real numbers
#F ========================================================
#F

# Notes:
# - RealDecompositionMonRep does not decompose into irss over the reals
#   if it is not a cyclic group. It will "almost" decompose. What is left
#   to do is to decompose tensor products of rotations in the tensordec case.
# - The real matrix decomposition functions work also for complex matrices
#   except the monmon one.

# InfoLatticeDec prints (little) info,
# InfoLatticeDec1 is for debugging purposes.
if not IsBound(InfoLatticeDec) then
  InfoLatticeDec := Ignore;
fi;
if not IsBound(InfoLatticeDec1) then
  InfoLatticeDec1 := Ignore;
fi;

if not IsBound(InfoAlgogen) then
  InfoAlgogen := Ignore;  # switch it on if you like
fi;
if not IsBound(RuntimeAlgogen) then
  RuntimeAlgogen := Ignore;  # switch it on to get runtime profile
fi;

#F Auxiliary functions
#F -------------------
#F

#F IsRealMon( <mon> )
#F   returns true if the monomialmatrix represented is real and false else.
#F

IsRealMon := function ( mon )
  if not IsMon(mon) then
    Error("<mon> must be a monomial operation");
  fi;
  return mon.char = 0 and ForAll(mon.diag, x -> GaloisCyc(x, -1) = x);
end;

#F IsRealRep( <rep> )
#F   returns true if <rep> is a real representation and false else.
#F

IsRealRep := function ( R )
  local S;

  if not IsARep(R) then
    Error("usage: IsRealRep( <R> )");
  fi;

  if IsBound(R.isReal) then
    return R.isReal;
  fi;

  if R.char <> 0 then
    R.isReal := false;
    return false;
  fi;

  if IsPermRep(R) then
    R.isReal := true;
    return true;
  fi;

  if IsMonRep(R) then
    S := MonARepARep(R);
    R.isReal := ForAll(S.theImages, x -> IsRealMon(x));
    return R.isReal;
  fi;

  # generic case
  S := MatARepARep(R);
  R.isReal :=
    ForAll(
      S.theImages, 
      m -> ForAll(m, r -> ForAll(r, c -> c = GaloisCyc(c, -1)))
    );
  return R.isReal;
end;

#F Decomposing real representations
#F --------------------------------
#F

#F RealDecompositionMonRep( <arep> )
#F   decomposes the monomial <arep> (over characteristic zero) of 
#F   an *abelian* group into irreducibles with respect to the *real* 
#F   number field and determines a highly structured 
#F   decomposition matrix A. 
#F   More precisely <arep> is decomposed as
#F     <arep> = 
#F       ConjugateARep(
#F         DirectSumARep(R_i, i = 1..k),
#F         A ^ -1
#F       ) 
#F   where all R_i are irreducible.
#F   Note, that the decomposition matrix A is accessible by 
#F   A = R.conjugation.element. A is simplified by the 
#F   function SimplifyAMat.
#F   The structure of A represents a fast algorithm for 
#F   multiplication with A.
#F

# The algorithm: (R is a real monomial representation of an abelian G)
#
#   Case 1: R is already irreducible.
#
#     The identity matrix of suitable size decomposes. 
#     Note that a rep of an abelian group is irreducible iff degree = 1, 
#
#   Case 2: R is not transitive.
#
#     Conjugate orbits with a permutation in a row and recurse
#     with the transitive constituents.
#
#   Case 4: G is cyclic
#
#     We conjugate with a perm onto a cyclic shift (onerep induced) or scaled
#     cyclic shift (-1-rep induced). The decomposition matrix is RDFT or RDFT3
#     respectively.
#
#   Case 7: Remaining case: R is a conjugated outer tensorproduct.
#
#     This is true since G is abelian and thus a product of cyclic group.

#     a. Conjugate R by a monomial matrix to be an outer 
#        tensorproduct R = (R1 # .. # Rk).
#
#     b. Recurse with the factors. The irreducibles of R are 
#        obtained by constructing all outer tensorproduct of
#        tuples of irreducibles of the factors.
#       
#        Note: the latter is not true since we are over the real numbers (think of
#        the tensor produce of rotations which is not irreducible. We have to further
#        decompose which ***I did not do yet*** But it won't creash.


RealDecompositionMonRep := function ( arg )
  local 
    G,              # R.source
    less,           # function to compare irr. reps
    monormatify,    # function to flatten reps
    permblocks,     # function to calculate blockpermutations
    partialTrace,   # function for the partial trace
    R,              # the rep
    K,              # the kernel
    AGK, AGK1,      # aggroups
    psi,            # corresponding bijection
    gens,           # minimal generating set
    R1, R2,         # R decomposed
    Ds,             # List of decomposed reps
    irrs, irrs1,    # irreducible reps
    GK,             # R.source/Kernel(R)
    phi,            # hom R.source -> GK
    ZpK,            # normal cyclic subgroup of GK of prime order p
    irr,            # an irredcuible rep
    ind,            # index of a generator
    gen,            # generator of a group
    genim,          # images of generators
    im,             # image of a generator
    imagegrp,       # group generated by the images
    twiddle,        # function for twiddles in primepower case
    Ts,             # twiddle matrices
    Zpk,            # cyclic group of order p ^ k
    Zp,             # preimage of ZpK under phi
    Sn,             # symmetric group
    M,              # matrix
    L,              # onedimensional rep
    Lext,           # extension of onedimensional rep to G
    D,              # decomposed rep
    blocks,         # blocks of decomposition
    nrfacs,         # number of tensorfactors
    degs,           # degrees of irrs
    perm,           # permutation
    kbss,           # kbs's of decomposed tensorfactors
    kbs1, kbs2,     # kbs's
    sum1, sum2,     # off-
    sum3,           # sets
    n, d, e, c,     # counter
    inds,           # index vectors
    RSG,            # RSG = R, RSG = (L_S induction G) ^ con1 
    con1,           # a diagonal matrix
    N,              # normal subgroup of R.source, index is prime
    RSNG,           # RSNG = RSG.rep, 
                    # RSNG = ((L_S induction N) induction G) ^ con2
    con2,           # a monomial matrix
    p,              # (R.source : N)
    t,              # element of R.source\N
    T,              # T = {t ^ 0, ..,t ^ (p - 1)}, TV of R.source\N
    RSNbyTtoG,      # RSNG = RSNbyTtoG, upper induction with TV T
    con3,           # RSNbyTtoG.conjugation, a monomial matrix
    testelms,
    perms,
    chars,
    char,
    char1,
    collirrs,       # irrs collected   
    rn,             # pair in collirrs 
    pos,            # position of an irr
    extendables,    # list of extendable r in irrs
    inducables,     # list of lists of the form 
                    #   [r_i | i in [0..p-1], r_i ~= r_1 ^ (t ^ i) ],
                    # with those r in irrs being not extendable
    extpermlist,    # indices of extendables in irrs
    indpermlist,    # indices of inducables in irrs
    ccs,            # conjugacy classes of N
    cc,             # conjugacy class in N
    tperm,          # permutation of t on ccs
    i, j, k, l,     # counter
    stop,           # boolean to exit a loop
    sortperm,       # permutation ordering irrs 
    extdeg,         # entire degree of extendables
    perm1, perm2,   # sorting
    perm3,          # permutations
    extrs,          # extended extendable
    extextendables, # extended extendables
    indrs,          # induced inducable
    indinducables,  # induced inducables
    indextendables, # induced extendables
    pcycle,         # p-cycle (1..p)
    corrperm,       # perm correcting induced inducables
    corrpermdegs,   # corresponding degrees
    corrdiag,       # blocks to correct induced inducables
    tprs,           # t^p evaluated at an inducable
    mult,           # multiplicity of a group of inducables
    indcons,        # making inner conjugates
    alldegs,        # blocks of decomposed lower rep
    rs,             # list of equivalent irrs
    ers,            # monormatified rs
    lins,           # onedim reps of R.source/N
    g, g1,          # group elements
    primeroots,     # list of p-th roots of unity
    allcons,        # list of matrices conjugating r_i onto r_1 ^ (t ^ i)
    lrs,            # l in lin times rs in extextendables
    cons,           # matrix conjugating r_i onto r_1 ^ (t ^ i)
    con4,           # permutation matrix
    con5,           # direct sum of allcons
    con6,           # permutation matrix
    con7,           # matrix with few blocks
    con8,           # permutation matrix
    con9,           # permutation matrix to sort irrs
    allirrs,        # irrs of induction
    allirrs1,       # monormatified irrs
    r,              # element in irrs
    chi,            # character of r
    timage,         # t ^ RSNdecext
    timage1,        # partial image of t
    con01, con02,   # correcture matrices 
    con03, con04,   # constructed for
    con05, con06,   # fast simplifying
    NK, NKs,        # normal subgroups of R.source/kernel(R)
    RN,             # restriction of R to N
    DR,             # R decomposed with the dec. matrix of N
    summandsDR,     # the summands of DR
    deg,            # degree of an irr
    chiirrs,        # character
    s,              # scalar product of two characters
    chin,           # character
    rchin,          # rep with character
    extsummand,     # direct sum of irrs with homogenous restriction
    intsummand,     # intertwining matrix
    extind,         # extended inducable
    extinds,        # sum of extended inducables
    M1, M2;         # matrices

  # a function to compare reps
  # via the character
  less := function ( R1, R2 )
    if not (
      IsARep(R1) and 
      IsARep(R2) and
      IsIdentical(R1.source, R2.source)
    ) then
      Error("<R1> and <R2> must be areps of the same source");
    fi;

    # make the trivial rep the smallest
    if ARepOps.IsTrivialOneRep(R1) then 
      return true;
    elif ARepOps.IsTrivialOneRep(R2) then 
      return false;
    fi;

    # compare degrees
    if R1.degree < R2.degree then
      return true;
    elif R2.degree < R1.degree then
      return false;
    fi;

    # decide by character
    # return CharacterARep(R1) <  CharacterARep(R2);
    return true;
  end;

  # given a list of positive integers L and a 
  # permutation p, permblocks construct a permutation
  # on [1..Sum(L)], which permutes succeding blocks
  # of lengths in L as p does.
  permblocks := function ( L, p )
    local n, B, i;

    n := 0;
    B := [ ];
    for i in L do
      Add(B, [n + 1..n + i]);
      n := n + i;
    od;

    return PermList(Concatenation(Permuted(B, p)));
  end;    


  # a function to convert an arep to a "mon"-arep
  # if possible, else to a "mat"-arep
  monormatify := function ( R )
    if IsMonRep(R) then
      return MonARepARep(R);
    fi;
    return MatARepARep(R);
  end;

  # a function to calculate the "partial trace",
  # given a square matrix of degree divisible by d,
  # the matrix is divided into d x d matrices,
  # then these are subsituted by their trace
  partialTrace := function( M, d )
    local n, Mtr, i, j;

    n   := DimensionsMat(M)[1]/d;
    Mtr := List([1..n], i -> [ ]);
    for i in [1..n] do
      for j in [1..n] do
	Mtr[i][j] := 
          Sum(List([1..d], l -> M[(i - 1)*d + l][(j - 1)*d + l]));
      od;
    od;

    return Mtr;
  end;

  # here starts the function
  # ------------------------

  # dispatch
  if Length(arg) = 1 then
    R := arg[1];
  else
    Error("usage: RealDecompositionMonRep( <arep> )");
  fi;

  # check arguments
  if not IsARep(R) then
    Error("usage: RealDecompositionMonRep( <arep> )");
  fi;

  # check for monrep and real
  if not IsMonRep(R) then
    Error("<R> must be a monrep");
  fi;
  if not IsRealRep(R) then
    Error("<R> must be a real representation");
  fi;

  # check abelian (maybe somebody will later extend to non-abelian groups)
  G  := R.source;
  K  := KernelARep(R);
  GK := G/K;
  if not IsAbelian(GK) then
    return false;
  fi;
  InfoLatticeDec1("#I+ check if faithful\n");

  # R is not faithful
  # -----------------
  if 
    not IsFaithfulARep(R) or 
    ( Length(MinimalGeneratingSet(AgGroup(G))) <> Length(G.theGenerators) 
      and Size(G) > 1 # this is because the mingenset has length 0
    )                 # for the trivial group
  then

    # compute kernel and factor group
    K   := KernelARep(R);
    GK  := G/K;
    phi := NaturalHomomorphism(G, GK);
    if Size(K) > 1 then
    InfoLatticeDec(
      "#I not faithful: ", 
      Size(G), " -> ", Size(G)/Size(K), " (group sizes)\n"
    );
    fi;

    # at the moment only the solvable case is of interest
    if IsSolvable(G) or IsSolvable(GK) then
    
      # compute an aggroup for GK with
      # minimal generating set
      # note that AGK and AGK1 are equal
      InfoLatticeDec1("#I+ construct aggroup\n");
      AGK  := AgGroup(GK);
      psi  := AGK.bijection;
      gens := MinimalGeneratingSet(AGK);
      if Length(gens) = 0 then
        gens := [AGK.identity];
      fi;
      AGK1 := GroupWithGenerators(gens);

      # construct representation of AGK1
      R1 := 
        ARepByImages(
          AGK1,
          List(
            gens,
            g -> 
              MonAMat(
                PreImagesRepresentative(phi, Image(psi, g)) ^ R
              )
          ),
          "faithful"
        );

      # decompose
      D := RealDecompositionMonRep(R1);

      # change to G, produce monreps if possible
      InfoLatticeDec1("#I+ translate to original group\n");
      L    := [ ];
      gens := List(G.theGenerators, g -> PreImage(psi, Image(phi, g)));
      for r in D.rep.summands do
        if IsMonRep(r) then
          Add(
            L,
            ARepByImages(
              G,
              List(gens, g -> MonAMat(g ^ r)),
              "hom"
            )
          );
        else
          Add(
            L,
            ARepByImages(
              G,
              List(gens, g -> MatAMat(g ^ r)),
              "hom"
            )
          );
         fi;
      od;

      # return result
      InfoLatticeDec("#I rep of degree ", R.degree, " completed\n");
      return
        ConjugateARep(
          DirectSumARep(L),
          D.conjugation
        );
    fi;
  fi;

  # R irreducible
  # -------------
  if IsIrreducibleARep(R) then
    InfoLatticeDec("#I irreducible\n");
    return 
      ConjugateARep(
        DirectSumARep(monormatify(R)),
        IdentityPermAMat(R.degree, R.char) ^ -1,
        "invertible"
      );
  fi;

  # R is not transitive: orbit decomposition
  # ----------------------------------------
  if not IsTransitiveMonRep(R) then
    R1   := OrbitDecompositionMonRep(R);
    InfoLatticeDec("#I orbit decomposition: ", R.degree, " -> ");
    InfoLatticeDec(R1.rep.summands[1].degree);
    for i in [2..Length(R1.rep.summands)] do
      InfoLatticeDec(" + ", R1.rep.summands[i].degree);
    od;
    InfoLatticeDec(" (degrees)\n");
    Ds := List(R1.rep.summands, RealDecompositionMonRep);

    if false in Ds then
      return false;
    fi;

    InfoLatticeDec1("#I+ simplifying decomposition matrix\n");
    con1 := 
      SimplifyAMat(
        R1.conjugation ^ -1 * 
        DirectSumAMat(List(Ds, r -> r.conjugation.element))
      );

    InfoLatticeDec("#I rep of degree ", R.degree, " completed\n");
    return
      ConjugateARep(
        DirectSumARep(
          List(
            Concatenation(List(Ds, r -> r.rep.summands)),
            monormatify
          )
        ),
        PowerAMat(con1, -1, "invertible"),
        "invertible"
      );
  fi;

  # at this point 
  # - the rep is transitive
  # - the group abelian
  # - the group has a minimal generating set
  # the cyclic case is easy

  # R.source is cyclic: terminate with suitable RDFTs
  # -------------------------------------------------
  if IsCyclic(R.source) then

    # the group should have one generator but check to be sure
    if Length(R.source.theGenerators) <> 1 then
      Error("<R>.source has more then one generator; should not happen");
    fi;

    R1 := TransitiveToInductionMonRep(R);

    # check whether R is an induced-conjugated onerep or -1-rep
    if IsPermRep(R1.rep.rep) then

      con1 := R1.conjugation;

      # conjugate R1.rep onto (1..n); then we can decompose using RDFT^T
      InfoLatticeDec1("#I+ computing conjugating perm\n");
      R1   := PermARepARep(R1.rep);
      gen  := R1.theImages[1];
      Sn   := SymmetricGroup(R.degree);
      con2 := 
        AMatPerm(
          RepresentativeOperation(
            Sn, 
            gen, 
            CyclicGroup(R1.degree).1
          ),
          R1.degree,
          R1.char
        );

      if R.degree = 3 then # choose a cheaper dec matrix
        con3 := AMatMat([ [ 1, 1, 0 ], [ 1, 0, 1 ], [ 1, -1, -1 ] ]);
      else
        con3 := RDFTAMat(1, R.degree, "transposed");
      fi;
#      con3 := AMatMat(spl.MatSPL(transforms.SRDFT(R.degree).transpose()));

      # construct irreducibles
      irrs := [ TrivialPermARep(R.source) ];
      n    := R.degree;
      if n mod 2 = 0 then
        Append(
          irrs, 
          List(
            [1..n/2-1], 
            i -> ARepByImages(R.source, [ MatAMat(RotationAMat(2*i/n)) ])
          )
        );
        Add(irrs, ARepByImages(R.source, [ Mon((), [-1]) ]));
      elif n = 3 then
        Add(irrs, ARepByImages(R.source, [ [[0,1],[-1,-1]] ]));
      else # n is odd
        Append(
          irrs, 
          List(
            [1..(n-1)/2], 
            i -> ARepByImages(R.source, [ MatAMat(RotationAMat(2*i/n)) ])
          )
        );
      fi;

      con3 := SimplifyAMat(con1^-1 * con2 * con3);
      return 
        ConjugateARep(
          DirectSumARep(irrs), PowerAMat(con3, -1, "invertible")
        );
    fi;

    # now R is a proper monrep, i.e., an induced -1-rep

    # construct the prototype that is decomposed by RDFT3^T
    # the prototype maps the generator to, e.g., 
    # Mon((1,2,3,4),[ -1, 1, 1, 1 ])
    R1 := 
      InductionARep(
        R1.rep.rep, 
        R.source, 
        List([1..R.degree], i -> R.source.theGenerators[1]^(i-1))
      );
    
    # conjugate R onto the prototype
    con1 := ConjugationTransitiveMonReps(R, R1);
    if R.degree = 3 then # choose a cheaper dec matrix
      con2 := AMatMat([ [ 1, 1, 0 ], [ -1, 0, 1 ], [ 1, -1, 1 ] ]);
    else
      con2 := RDFTAMat(3, R.degree, "transposed");
    fi;
#    con2 := AMatMat(spl.MatSPL(transforms.SRDFT3(R.degree).transpose()));

    # construct irreducibles
    n    := R.degree;
    if n mod 2 = 0 then
      irrs :=
        List( 
          [1..n/2], 
          i -> ARepByImages(R.source, [ MatAMat(RotationAMat((2*i-1)/n)) ])
        );
    elif n = 3 then
      irrs := [ ARepByImages(R.source, [ Mon((), [-1]) ]), 
                ARepByImages(R.source, [ [[0,1],[-1,1]] ]) ];
    else # n is odd
      irrs :=
        List(
          [1..(n-1)/2], 
          i -> ARepByImages(R.source, [ MatAMat(RotationAMat((2*i-1)/n)) ])
        );
      Add(irrs, ARepByImages(R.source, [ Mon((), [-1]) ]));
    fi;

    con3 := SimplifyAMat(con1 * con2);
    return 
      ConjugateARep(
        DirectSumARep(irrs), PowerAMat(con3, -1, "invertible")
      );
  fi;

  # note: in the real case, the tensor product of two irrs is in general
  # not irr again; think of two rotations; thus further decomposition may
  # be required which I did not implement yet 

  # outer tensorproduct: recurse with factors
  # -----------------------------------------
  # in the abelian case we always want to try this decomposition
  # because its fast (not all normal subgroups are computed)
  if IsAbelian(G) then
    R1     := OuterTensorProductDecompositionMonRep(R);
    nrfacs := Length(R1.rep.factors);
    if nrfacs > 1 then
      InfoLatticeDec(
	"#I outer tensorproduct: ",
	R.degree, " -> " 
      );
      for i in [1..nrfacs - 1] do
	InfoLatticeDec(R1.rep.factors[i].degree);
	InfoLatticeDec(" * ");
      od;
      InfoLatticeDec(R1.rep.factors[nrfacs].degree);
      InfoLatticeDec(" (degrees)\n");

      # calculate permutation conjugating irreducibles
      # of the tensorproduct in a row. Note, that the
      # irreducibles are ordered lexicographically with
      # respect to the ordering of the irreducibles of
      # the factors
      Ds := List(R1.rep.factors, r -> RealDecompositionMonRep(r));
      if false in Ds then
        return false;
      fi;
      InfoLatticeDec1("#I+ factors decomposed\n");

      # kbs of the factors
      kbss := [ ];
      for i in [1..nrfacs] do
	kbss[i] := [ ];
	degs    := List(Ds[i].rep.summands, r -> r.degree);
	n       := 0;
	for d in degs do
	  Add(kbss[i], [n + 1..n + d]);
	od;
      od;

      perm1 := ( );
      L     := kbss[nrfacs];
      sum1  := R1.rep.factors[nrfacs].degree;

      # sort from the rear
      for n in [nrfacs - 1, nrfacs - 2..1] do
	kbs1 := kbss[n];
	kbs2 := List(L, l -> List(l, i -> i ^ perm1));
	L    := [ ];
	sum2 := 0;
	for d in kbs1 do
	  sum3 := 0;
	  for e in kbs2 do
	    Add(
	      L, 
	      sum2 + 
	      sum3 +
	      Concatenation(
		List(
		  [0..Length(d) - 1], 
		  j -> [j * sum1 + 1..j * sum1 + Length(e)]
		)
	      )
	    );
	    sum3 := sum3 + Length(e);
	  od;
	  sum2 := sum2 + Length(d) * sum1;
	od;
	sum1 := sum1 * R1.rep.factors[n].degree;
	perm1 := 
	  perm1 * 
	  TensorProductPerm(
	    [R1.degree/sum1,                            sum1], 
	    [            (), PermList(Concatenation(L)) ^ -1]
	  );
      od;

      # collect irrs of the factors by equality
      collirrs := [ ];
      blocks   := [ ];
      for i in [1..nrfacs] do
	irrs        := Ds[i].rep.summands;
	collirrs[i] := [ ];
	blocks[i]   := [ ];
	j           := 0;
	pos         := 0;
	while j < Length(irrs) do
	  j := j + 1;
	  r := irrs[j];
	  n := 1;
	  while j < Length(irrs) and irrs[j + 1] = r do
	    n := n + 1;
	    j := j + 1;
	  od;
	  Add(collirrs[i], [r, n]);
	  Add(blocks[i], [pos + 1..pos + n]);
	  pos := pos + n;
	od;
      od;

      # perm to bring equivalent tensor products together
      inds  := 
	Cartesian(
	  List(
	    [1..nrfacs], 
	    i -> [1..Length(Ds[i].rep.summands)]
	  )
	);
      perm2 := [ ];
      for l in Concatenation(List(Cartesian(blocks), Cartesian)) do
	Add(perm2, Position(inds, l));
      od;
      perm2 := PermList(perm2) ^ -1;

      blocks := 
	List(
	  inds, 
	  l -> 
	    Product(
	      List([1..nrfacs], i -> Ds[i].rep.summands[ l[i] ].degree)
	    )
	);

      # construct irrs
      InfoLatticeDec1("#I+ ");
      for i in [1..nrfacs - 1] do
	InfoLatticeDec1(Length(Ds[i].rep.summands), " * ");
      od;
      InfoLatticeDec1(Length(Ds[nrfacs].rep.summands), " many irrs\n");
      perm2 := permblocks(blocks, perm2) ^ -1;
      irrs  := [ ];
      for l in Cartesian(collirrs) do
	Add(
	  irrs, 
	  [ monormatify(
	      OuterTensorProductARep(G, List(l, p -> p[1]))
	    ),
	    Product(List(l, p -> p[2]))
	  ]
	);
      od;

      # sort irrs
      InfoLatticeDec1("#I sorting irrs\n");
      perm3  := [1..Length(irrs)];
      blocks := List(irrs, r -> r[1].degree * r[2]);
      SortParallel(
	irrs, 
	perm3, 
	function(r1, r2) return less(r1[1], r2[1]); end
      );
      perm3 := permblocks(blocks, PermList(perm3) ^ -1) ^ -1;
      con1  := 
	R1.conjugation ^ -1 *
	SimplifyAMat(TensorProductAMat(List(Ds, d -> d.conjugation.element))) *
	AMatPerm(perm1 * perm2 * perm3, R.degree, R.char);

      # set the field .isMonMat, because it is 
      # expensive to check
      con1.isMonMat := 
	ForAll(List(Ds, d -> d.conjugation.element), IsMonMat);

      InfoLatticeDec1("#I+ simplifying decomposition matrix\n");
      con1 := SimplifyAMat(con1);

      InfoLatticeDec("#I rep of degree ", R.degree, " completed\n");
      return 
	ConjugateARep(
	  DirectSumARep(
	    Concatenation(
	      List(irrs, r -> List([1..r[2]], i -> r[1]))
	    )
	  ),
	  PowerAMat(con1, -1, "invertible"),
	  "invertible"
	);
    fi;
  fi;

  Error("you should not have gotten to this point");
end;


# Test the real decomposition on the symmetries of some transforms
testRealDecMonRep := function ( )
  local L;

  L := List([2..20], n -> MonMonSymmetry(DCT_VIIIunscaled(n)));
  return List(L, p -> 
    RealDecompositionMonRep(p[1]) = p[1] and
    RealDecompositionMonRep(p[2]) = p[2]
    );
end;


#F Decomposing matrices over the reals
#F -----------------------------------
#F

#F RestrictToAbelianSymmetry ( <symmetry> )
#F   <symmetry> is a pair of representations of the same group as 
#F   produced by the various symmetry functions. This function
#F   restricts both reps to one of the largest abelian subgroups
#F   and returns a pair of areps of type "restriction".
#F   This way, the function RealDecompositionMonRep will always 
#F   succeed.
#F

RestrictToAbelianSymmetry := function ( L )
  local G, Hs, H;

  # check arg
  if not ( IsList(L) and Length(L) = 2 and 
    ForAll(L, IsARep) and L[1].source = L[2].source ) then
    Error("<L> must be a list of two reps of the same group");
  fi;
  
  # catch abelian case
  G := L[1].source;
  if IsAbelian(G) then
    return List(L, R -> RestrictionARep(R, G));
  fi;

  # determine the largest abelian subgroup and return
  # note that in general there are choices
  # both ConjugacyClassesSubgroups and MaximalSubgroups are slow but
  # MaximalNormalSubgroups seems fast; hence we first try the latter
  # and see whether we luck out
  Hs := Filtered(MaximalNormalSubgroups(G), IsAbelian);
  if Hs <> [ ] then
    H := GroupWithGenerators(Hs[1]);
  else
    Hs := 
      Filtered(
        List(ConjugacyClassesSubgroups(G), H -> H.representative),
        IsAbelian
      );
    H := GroupWithGenerators(Hs[Length(Hs)]);
  fi;

  return List(L, R -> RestrictionARep(R, H));
end;


#F PRealMatrixDecompositionByPermPermSymmetry( <mat/amat> )
#F   decomposes <mat/amat> into a product of sparse
#F   matrices according to the perm-perm symmetry.
#F   An amat is returned representing the product.
#F   In contrast to its counterpart without the prefix "Real"
#F   This function decomposes the symmetry over the real numbers.
#F   So if the supplied matrix is real, then so is the decomposition.
#F

PRealMatrixDecompositionByPermPermSymmetry := function ( M )
  local Rs, RL, RR, DL, DR, P, AL, AR, A, t1, t2, t3, t4;

  if not ( IsMat(M) or IsAMat(M) ) then
    Error("<M> must be a <mat/amat>");
  fi;

  # calculate the permperm symmetry
  t1 := Runtime();
  InfoAlgogen("#I CALCULATING THE PERMPERM SYMMETRY\n");
  Rs := PermPermSymmetry(M);

  # now restrict to abelian symmetry
  Rs := RestrictToAbelianSymmetry(Rs);
  RL := Rs[1];
  RR := Rs[2];

  # decompose the reps
  # if the reps are equivalent by 
  # a permutation, only one of 
  # them has to be decomposed
  InfoAlgogen("#I DECOMPOSING THE REPS\n");
  t2 := Runtime();
  DL := RealDecompositionMonRep(RL);
  AL := DL.conjugation.element;
  if IsEquivalentARep(RL, RR) then
    P := ConjugationPermReps(RL, RR); 
    if P <> false then
      if IsIdentityMat(P) then
	AR := AL;
      else
        AR := P * AL;
      fi;
    else
      DR := RealDecompositionMonRep(RR);
      AR := DR.conjugation.element;
    fi;
  else
    DR := RealDecompositionMonRep(RR);
    AR := DR.conjugation.element;
  fi;

  # the block matrix
  InfoAlgogen("#I SPECIALIZING\n");
  t3 := Runtime();
  if IsMat(M) then
    M := AMatMat(M);
  fi;
  A := 
    AL *
    AMatSparseMat(MatAMat(InverseAMat(AL) * M * InverseAMat(PseudoInverseAMat(AR))), false) *
    PseudoInverseAMat(AR);

  # avoid that A is checked for monomiality
  # by SimplifyAMat
  A.isMonMat := IsMonMat(M);
  A  := SimplifyAMat(A);
  t4 := Runtime();
  RuntimeAlgogen(
    "finding symmetry: ", t2 - t1, "\n",
    "decomposing symmetry: ", t3 - t2, "\n",
    "specializing: ", t4 - t3, "\n",
    "total: ", t4 - t1, "\n"
  );
  return A;
end;


#F PRealMatrixDecompositionByMonMonSymmetry( <mat/amat> )
#F   decomposes a *real* <mat/amat> into a product of sparse
#F   matrices according to the mon-mon symmetry.
#F   An amat is returned representing the product.
#F   In contrast to its counterpart without the prefix "Real"
#F   This function decomposes the symmetry over the real numbers.
#F

PRealMatrixDecompositionByMonMonSymmetry := function ( arg )
  local M, Rs, RL, RR, DL, DR, AL, AR, A, t1, t2, t3, t4;

  if Length(arg) = 1 then
    M    := arg[1];
  else
    Error(
      "usage: ",
      "  RealMatrixDecompositionByMonMonSymmetry( <mat/amat> )"
    );
  fi;

  if not ( IsMat(M) or IsAMat(M) ) then
    Error("<M> must be a <mat/amat>");
  fi;

  # calculate the monmon symmetry
  InfoAlgogen("#I CALCULATING THE MONMON SYMMETRY\n");
  t1 := Runtime();
  if IsAMat(M) then 
    M := MatAMat(M);
  fi;
  if not ForAll(M, r -> ForAll(r, c -> IsDouble(c) or GaloisCyc(c, -1) = c)) then
    Error("<M> must be a real matrix");
  fi;
  Rs := MonMonSymmetry(M);

    InfoAlgogen("#I Size of symmetry group: ", Size(Rs[1].source), "\n");

  # now restrict to abelian symmetry
  Rs := RestrictToAbelianSymmetry(Rs);
  RL := Rs[1];
  RR := Rs[2];

  # decompose the reps
  InfoAlgogen("#I DECOMPOSING THE SYMMETRY\n");
  t2 := Runtime();
  DL := RealDecompositionMonRep(RL);
  DR := RealDecompositionMonRep(RR);
  AL := DL.conjugation.element;
  AR := DR.conjugation.element;

  # the block matrix
  InfoAlgogen("#I SPECIALIZING\n");
  t3 := Runtime();
  if IsMat(M) then
    M := AMatMat(M);
  fi;
  A := 
    AL *
    AMatSparseMat(MatAMat(InverseAMat(AL) * M * InverseAMat(PseudoInverseAMat(AR))), false) *
    PseudoInverseAMat(AR);

  # avoid that A is checked for monomiality
  # by SimplifyAMat
  A.isMonMat := IsMonMat(M);
  A  := SimplifyAMat(A);
  t4 := Runtime();
  RuntimeAlgogen(
    "finding symmetry: ", t2 - t1, "\n",
    "decomposing symmetry: ", t3 - t2, "\n",
    "specializing: ", t4 - t3, "\n",
    "total: ", t4 - t1, "\n"
  );
  return A;
end;


#F RealMatrixDecompositionByPermIrredSymmetry( <mat/amat> [, <maxblocksize> ] )
#F   decomposes <mat/amat> into a product of sparse
#F   matrices according to the perm-irred symmetry
#F   returned by the function PermIrredSymmetry1.
#F   An amat is returned representing the product.
#F   Only those symmetries where all irreducibles 
#F   are of degree <= <maxblocksize> are considered. 
#F   The default for <maxblocksize> is 2.
#F   Among all symmetries [RL, RR] the best is chosen 
#F   according to the following measure.
#F   If
#F     RL ~= RR ~= directsum R_i^(n_i), and Q = sum n_i^2 * d_i^2,
#F   with d_i = deg(R_i), then the best symmetry has
#F   the smallest value of Q.
#F
#F   In contrast to its counterpart without the prefix "Real"
#F   This function decomposes the symmetry over the real numbers.
#F   So if the supplied matrix is real, then so is the decomposition.
#F

RealMatrixDecompositionByPermIrredSymmetry := function ( arg )
  local M, max, dim, Rs, Qs, min, pos, R, D, A, t1, t2, t3, t4;

  # decode and check arguments
  if Length(arg) = 1 then
    M   := arg[1];
    max := 2;
  elif Length(arg) = 2 then
    M   := arg[1];
    max := arg[2];
  else
    Error(
      "usage: \n", 
      "  RealMatrixDecompositionByPermIrredSymmetry( ",
      "    <mat/amat> [, <maxblocksize> ]  )"
    );
  fi;
  if IsAMat(M) then
    M := MatAMat(M);
  fi;
  if not IsMat(M) then
    Error("<M> must be a matrix");
  fi;
  if not ( IsInt(max) and max >= 1 ) then
    Error("<max> must be a posiive integer");
  fi;

  dim := DimensionsMat(M);
  if dim[1] <> dim[2] then
    return AMatMat(M);
  fi;

  # calculate the symmetry
  # use PermIrredSymmetry1 for time reasons
  InfoAlgogen("#I CALCULATING THE PERMIRRED SYMMETRY\n");
  t1 := Runtime();
  Rs := PermIrredSymmetry1(M, max);
  if Length(Rs) > 0 then
    
    # take the best pair for decomposition,
    # let R = directsum R_i^(n_i) be the decomposition
    # of the right (or left) side of the perm-irred symmetry
    # into irreducibles, then the quality is given by 
    # a small value of 
    #   sum n_i^2 * d_i^2, 
    # where d_i = deg(R_i)
    InfoAlgogen("#I CHOOSING SYMMETRY\n");
    Qs := 
      List(
        Rs, 
        p -> 
          Sum(
	    List(
	      Collected(
		List(p[2].rep.summands, r -> CharacterARep(r))
	      ),
	      cn -> Degree(cn[1])^2 * cn[2]^2
	    )
          )
      );
    min := Minimum(Qs);
    pos := PositionProperty(Qs, q -> q = min);
    R   := Rs[pos];

    # now restrict to abelian symmetry
    R := RestrictToAbelianSymmetry(R);

    InfoAlgogen("#I DECOMPOSING THE SYMMETRY\n");
    t2 := Runtime();
    D  := RealDecompositionMonRep(R[1]).conjugation.element;

    # the block matrix
    t3 := Runtime();
    InfoAlgogen("#I SPECIALIZING\n");
    M := AMatMat(M);
    A := 
      D *
      AMatSparseMat(
        MatAMat(InverseAMat(D) * M * InverseAMat(R[2].rep.conjugation)), 
        false
      ) *
      R[2].rep.conjugation;

    # avoid that A is checked for monomiality
    # by SimplifyAMat
    A.isMonMat := IsMonMat(M);
    A  := SimplifyAMat(A);
    t4 := Runtime();
    RuntimeAlgogen(
      "finding symmetry: ", t2 - t1, "\n",
      "decomposing symmetry: ", t3 - t2, "\n",
      "specializing: ", t4 - t3, "\n",
      "total: ", t4 - t1, "\n"
    );
    return A;
  fi;

  # decomposition failed
  return AMatMat(M);

end;


#F RealMatrixDecompositionByMon2IrredSymmetry( <mat/amat> [, <maxblocksize> ] )
#F   decomposes <mat/amat> into a product of sparse
#F   matrices according to the mon2-irred symmetry
#F   returned by the function Mon2IrredSymmetry1.
#F   The Mon2IrredSymmetry considers all monomial representations
#F   with entries +/-1.
#F   An amat is returned representing the product.
#F   Only those symmetries where all irreducibles
#F   are of degree <= <maxblocksize> are considered.
#F   The default for <maxblocksize> is 2.
#F   Among all symmetries [RL, RR] the best is chosen
#F   according to the following measure.
#F   If
#F     RL ~= RR ~= directsum R_i^(n_i), and Q = sum n_i^2 * d_i^2,
#F   with d_i = deg(R_i), then the best symmetry has
#F   the smallest value of Q.
#F
#F   In contrast to its counterpart without the prefix "Real"
#F   This function decomposes the symmetry over the real numbers.
#F   So if the supplied matrix is real, then so is the decomposition.
#F

RealMatrixDecompositionByMon2IrredSymmetry := function ( arg )
  local M, max, dim, Rs, Qs, min, pos, R, D, A, t1, t2, t3, t4;

  # decode and check arguments
  if Length(arg) = 1 then
    M   := arg[1];
    max := 2;
  elif Length(arg) = 2 then
    M   := arg[1];
    max := arg[2];
  else
    Error(
      "usage: \n",
      "  RealMatrixDecompositionByMon2IrredSymmetry( ",
      "    <mat/amat> [, <maxblocksize> ]  )"
    );
  fi;
  if IsAMat(M) then
    M := MatAMat(M);
  fi;
  if not IsMat(M) then
    Error("<M> must be a matrix");
  fi;
  if not ( IsInt(max) and max >= 1 ) then
    Error("<max> must be a posiive integer");
  fi;

  dim := DimensionsMat(M);
  if dim[1] <> dim[2] then
    return AMatMat(M);
  fi;

  # calculate the symmetry
  # use Mon2IrredSymmetry1 for time reasons
  InfoAlgogen("#I CALCULATING THE MON2IRRED SYMMETRY\n");
  t1 := Runtime();
  Rs := Mon2IrredSymmetry1(M, max);
  if Length(Rs) > 0 then

    # take the best pair for decomposition,
    # let R = directsum R_i^(n_i) be the decomposition
    # of the right (or left) side of the perm-irred symmetry
    # into irreducibles, then the quality is given by
    # a small value of
    #   sum n_i^2 * d_i^2,
    # where d_i = deg(R_i)
    InfoAlgogen("#I CHOOSING SYMMETRY\n");
    Qs :=
      List(
        Rs,
        p ->
          Sum(
            List(
              Collected(
                List(p[2].rep.summands, r -> CharacterARep(r))
              ),
              cn -> Degree(cn[1])^2 * cn[2]^2
            )
          )
      );
    min := Minimum(Qs);
    pos := PositionProperty(Qs, q -> q = min);
    R   := Rs[pos];

    # now restrict to abelian symmetry
    R := RestrictToAbelianSymmetry(R);

    InfoAlgogen("#I DECOMPOSING THE SYMMETRY\n");
    t2 := Runtime();
    D  := RealDecompositionMonRep(R[1]).conjugation.element;

    # the block matrix
    InfoAlgogen("#I SPECIALIZING\n");
    t3 := Runtime();
    M := AMatMat(M);
    A :=
      D *
      AMatSparseMat(
        MatAMat(InverseAMat(D) * M * InverseAMat(R[2].rep.conjugation)),
        false
      ) *
      R[2].rep.conjugation;

    # avoid that A is checked for monomiality
    # by SimplifyAMat
    A.isMonMat := IsMonMat(M);
    A  := SimplifyAMat(A);
    t4 := Runtime();
    RuntimeAlgogen(
      "finding symmetry: ", t2 - t1, "\n",
      "decomposing symmetry: ", t3 - t2, "\n",
      "specializing: ", t4 - t3, "\n",
      "total: ", t4 - t1, "\n"
    );
    return A;
  fi;

  # decomposition failed
  return AMatMat(M);

end;


# lousy try for a master function.
# the new thing compared to the above is that it first 
# throws out zero rows and columns

PRealMatrixDecomposition := function ( M )
  local A, A1;

  if IsAMat(M) then
    M := MatAMat(M);
  fi;

  A := AMatSparseMat(M);

  # now replace the amats of type mat in the known structure of A
  # by their decomposed counterparts
  for A1 in A.factors[3].summands do
     A1.factors[2] := PRealMatrixDecompositionByMonMonSymmetry(A1.factors[2]);
  od;

  return SimplifyAMat(A);
end;


# test the matrix dec functions on transforms
testRealMatDec := function ( )

  return List([2..20], 
    n -> MatAMat(PRealMatrixDecompositionByMonMonSymmetry(DCT_IIunscaled(n)))
      = DCT_IIunscaled(n)
    );
end;
