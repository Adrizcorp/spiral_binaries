# -*- Mode: shell-script -*- 

#############################################################################
##
#A  gaussian.g                  GAP library                  Martin Schoenert
##
##
#Y  Copyright (C) 2018-2019, Carnegie Mellon University
#Y  All rights reserved.  See LICENSE for details.
#Y  
#Y  This work is based on GAP version 3, with some files from version 4.  GAP is
#Y  Copyright (C) (1987--2019) by the GAP Group (www.gap-system.org).
##
##  This file contains those functions that  deal  with  Gaussian  rationals.
##
##  Gaussian rationals are elements of the form $a + b * I$ where  $I$ is the
##  square root of -1 and $a,b$  are rationals.  Note that  $I$ is written as
##  'E(4)', i.e., as a  fourth root of unity in  GAP.  Gauss was the first to
##  investigate such numbers, and already proved that the ring of integers of
##  this field, i.e.,  the elements of the  form $a +  b * I$ where $a,b$ are
##  integers, forms a Euclidean Ring.  It follows that  this ring is a Unique
##  Factorization Domain.
##
##


#############################################################################
##
#F  IsGaussInt(<x>) . . . . . . . . . test if an object is a Gaussian integer
##
##  'IsGaussInt' returns 'true' if the  object <x> is  a Gaussian integer and
##  'false' otherwise.  Gaussian integers are of the form  '<a> + <b>\*E(4)',
##  where <a> and <b> are integers.
##
IsGaussInt := function ( x )
    return IsCycInt( x ) and (NofCyc( x ) = 1 or NofCyc( x ) = 4);
end;


#############################################################################
##
#V  GaussianIntegers  . . . . . . . . . . . . . . domain of Gaussian integers
#V  GaussianIntegersOps . . . . . . .  operation record for Gaussian integers
##
GaussianIntegersOps := OperationsRecord( "GaussianIntegersOps", RingOps );

GaussianIntegers := rec(
    isDomain                    := true,
    isRing                      := true,

    generators                  := [ 1, E(4) ],
    zero                        := 0,
    one                         := 1,
    name                        := "GaussianIntegers",

    size                        := "infinity",
    isFinite                    := false,
    isCommutativeRing           := true,
    isIntegralRing              := true,
    isUniqueFactorizationRing   := true,
    isEuclideanRing             := true,
    units                       := Set([ 1, -1, E(4), -E(4) ]),

    operations                  := GaussianIntegersOps
);


#############################################################################
##
#F  GaussianIntegersOps.Ring(<elms>) ring generated by some Gaussian Integers
##
GaussianIntegersOps.Ring := function ( elms )
    if ForAll( elms, IsInt )  then
        return Integers;
    else
        return GaussianIntegers;
    fi;
end;


#############################################################################
##
#F  GaussianIntegersOps.DefaultRing(<elms>) . . default ring of some Gaussian
#F                                                                   integers
##
GaussianIntegersOps.DefaultRing := function ( elms )
    return GaussianIntegers;
end;


#############################################################################
##
#F  GaussianIntegersOps.\in(<g>,<GaussInt>)  . . . . . . membership test for
#F                                                          Gaussian integers
##
##  'GaussianIntegersOps.in' returns 'true' if the object  <g>  is a Gaussian
##  integer and 'false' otherwise.  Gaussian integers are of the form  '<a> +
##  <b>\*E(4)', where <a>  and   <b> are   integers.
##
GaussianIntegersOps.\in := function ( x, GaussInt )
    return IsCycInt( x ) and (NofCyc( x ) = 1 or NofCyc( x ) = 4);
end;


#############################################################################
##
#F  GaussianIntegersOps.Random(<GaussInt>)  . . . . . random Gaussian integer
##
##  'GaussianIntegersOps.Random' returns a  random  Gaussian  integer,  i.e.,
##  $a + b E(4)$, where $a$ and $b$ are  random integers,  selected  with the
##  generator 'Random( Integers )' (see "Random", "RandomInt").
##
GaussianIntegersOps.Random := function ( GaussInt )
    return Random( Integers ) + Random( Integers ) * E(4);
end;


#############################################################################
##
#F  GaussianIntegersOps.Quotient(<GaussInt>,<x>,<y>)  . . . . quotient of two
#F                                                          Gaussian integers
##
GaussianIntegersOps.Quotient := function ( GaussInt, x, y )
    local   q;
    q := x / y;
    if not IsCycInt( q )  then
        q := false;
    fi;
    return q;
end;


#############################################################################
##
#F  GaussianIntegersOps.IsAssociated(<GaussInt>,<x>,<y>)  . . . . test if two
#F                                            Gaussian integers are associate
##
##  'GaussianIntegersOps.IsAssociated'  returns  'true'   if   the   Gaussian
##  integers <x> and <y> are assocaited and 'false' otherwise.
##
GaussianIntegersOps.IsAssociated := function ( GaussInt, x, y )
    return x = y  or x = -y  or x = E(4)*y  or x = -E(4)*y;
end;


#############################################################################
##
#F  GaussianIntegersOps.StandardAssociate(<GaussInt>,<x>)  standard associate
#F                                                      of a Gaussian integer
##
##  'GaussianIntegersOps.StandardAssociate' returns the standard associate of
##  the Gaussian integer <x>.  The standard associate of <x> is an associated
##  element <y> of <x> that lies in the  first quadrant of the complex plain.
##  That  is <y>  is  that element   from '<x> * [1,-1,E(4),-E(4)]' that  has
##  positive real part and nonnegative imaginary part.
##
##  'GaussianIntegersOps.StandardAssociate' is the  generalization  of  'Abs'
##  (see "Abs") for Gaussian integers.
##
GaussianIntegersOps.StandardAssociate := function ( GaussInt, x )
    if   IsRat(x)  and 0 <= x  then
        return x;
    elif IsRat(x)  then
        return -x;
    elif 0 <  COEFFSCYC(x)[1]       and 0 <= COEFFSCYC(x)[2]       then
        return x;
    elif      COEFFSCYC(x)[1] <= 0  and 0 <  COEFFSCYC(x)[2]       then
        return - E(4) * x;
    elif      COEFFSCYC(x)[1] <  0  and      COEFFSCYC(x)[2] <= 0  then
        return - x;
    else
        return E(4) * x;
    fi;
end;


#############################################################################
##
#F  GaussianIntegersOps.EuclideanDegree(<GaussInt>,<x>) . .  Euclidean degree
#F                                                      of a Gaussian integer
##
GaussianIntegersOps.EuclideanDegree := function ( GaussInt, x )
    return x * GaloisCyc( x, -1 );
end;


#############################################################################
##
#F  GaussianIntegersOps.EuclideanRemainder(<GaussInt>,<x>,<y>)   .  remainder
##
GaussianIntegersOps.EuclideanRemainder := function ( GaussInt, x, y )
    return x - RoundCyc( x/y ) * y;
end;


#############################################################################
##
#F  GaussianIntegersOps.EuclideanQuotient(<GaussInt>,<x>,<y>) . . .  quotient
##
GaussianIntegersOps.EuclideanQuotient := function ( GaussInt, x, y )
    return RoundCyc( x/y );
end;


#############################################################################
##
#F  GaussianIntegersOps.QuotientRemainder(<GaussInt>,<x>,<y>) . . quo and rem
##
GaussianIntegersOps.QuotientRemainder := function( GaussInt, x, y )
    local   q;

    q := RoundCyc(x/y);
    return [ q, x-q*y ];
end;


#############################################################################
##
#F  GaussianIntegersOps.IsPrime(<GaussInt>,<x>) . . . test whether a Gaussian
#F                                                         integer is a prime
##
GaussianIntegersOps.IsPrime := function ( GaussInt, x )
    if IsInt( x )  then
        return x mod 4 = 3  and IsPrimeInt( x );
    else
        return IsPrimeInt( x * GaloisCyc( x, -1 ) );
    fi;
end;


#############################################################################
##
#F  TwoSquares(<n>) . .  representation of an integer as a sum of two squares
##
##  'TwoSquares' returns a list of two integers $x\<=y$ such that  the sum of
##  the squares of $x$ and $y$ is equal to the nonnegative integer <n>, i.e.,
##  $n = x^2+y^2$.  If no such representation exists 'TwoSquares' will return
##  'false'.  'TwoSquares' will return a representation for which the  gcd of
##  $x$  and   $y$ is  as  small  as  possible.    It is not  specified which
##  representation 'TwoSquares' returns, if there are more than one.
##
##  Let $a$ be the product of all maximal powers of primes of the form $4k+3$
##  dividing $n$.  A representation of $n$ as a sum of two squares  exists if
##  and only if $a$ is a perfect square.  Let $b$ be the maximal power of $2$
##  dividing $n$ or its half, whichever is a perfect square.  Then the minmal
##  possible gcd of $x$ and $y$ is the square root $c$ of $a b$.  The  number
##  of different minimal representation with $x\<=y$ is $2^{l-1}$, where  $l$
##  is the number of different prime factors of the form $4k+1$ of $n$.
##
##  The algorithm first finds a square root $r$ of $-1$  modulo  $n / (a b)$,
##  which must exist, and applies the Euclidean algorithm  to  $r$  and  $n$.
##  The first residues in the sequence that are smaller than $\root{n/(a b)}$
##  times $c$ are a possible pair $x$ and $y$.
##
##  Better descriptions of the algorithm and related topics can be found  in:
##  S. Wagon,  The Euclidean Algorithm Strikes Again, AMMon 97, 1990, 125-129
##  D. Zagier, A One-Sentence Proof that Every Pri.., AMMon 97, 1990, 144-144
##
TwoSquares := function ( n )
    local  c, d, p, q, l, x, y;

    # check arguments and handle special cases
    if   n < 0  then Error("<n> must be positive");
    elif n = 0  then return [ 0, 0 ];
    elif n = 1  then return [ 0, 1 ];
    fi;

    # write $n = c^2 d$, where $c$ has only  prime factors  $2$  and  $4k+3$,
    # and $d$ has at most one  $2$ and otherwise only  prime factors  $4k+1$.
    c := 1;  d := 1;
    for p  in Set( FactorsInt( n ) )  do
        q := p;  l := 1;
        while n mod (q * p) = 0  do q := q * p;  l := l + 1;  od;
        if p = 2  and l mod 2 = 0  then
            c := c * 2 ^ (l/2);
        elif p = 2  and l mod 2 = 1  then
            c := c * 2 ^ ((l-1)/2);
            d := d * 2;
        elif p mod 4 = 1  then
            d := d * q;
        elif p mod 4 = 3  and l mod 2 = 0  then
            c := c * p ^ (l/2);
        else # p mod 4 = 3  and l mod 2 = 1
            return false;
        fi;
    od;

    # handle special cases
    if   d = 1  then return [ 0, c ];
    elif d = 2  then return [ c, c ];
    fi;

    # compute a square root $x$ of $-1$ mod $d$,  which must exist  since  it
    # exists modulo all prime powers that divide $d$
    x := RootMod( -1, d );

    # and now the Euclidean Algorithm strikes again
    y := d;
    while d < y^2  do
        p := x;
        x := y mod x;
        y := p;
    od;

    # return the representation
    return [ c * x, c * y ];
end;


#############################################################################
##
#F  GaussianIntegersOps.Factors(<GaussInt>,<x>) . . . . .  factorization of a
#F                                                           Gaussian integer
##
GaussianIntegersOps.Factors := function ( GaussInt, x )
    local   facs,       # factors (result)
            prm,        # prime factors of the norm
            tsq;        # representation of prm as $x^2 + y^2$

    # handle trivial cases
    if x in [ 0, 1, -1, E(4), -E(4) ]  then
        return [ x ];
    fi;

    # loop over all factors of the norm of x
    facs := [];
    for prm  in Set( FactorsInt( EuclideanDegree( x ) ) )  do

        # $p = 2$ and primes $p = 1$ mod 4 split according to $p = x^2 + y^2$
        if prm = 2  or prm mod 4 = 1  then
            tsq := TwoSquares( prm );
            while IsCycInt( x / (tsq[1]+tsq[2]*E(4)) )  do
                Add( facs, (tsq[1]+tsq[2]*E(4)) );
                x := x / (tsq[1]+tsq[2]*E(4));
            od;
            while IsCycInt( x / (tsq[2]+tsq[1]*E(4)) )  do
                Add( facs, (tsq[2]+tsq[1]*E(4)) );
                x := x / (tsq[2]+tsq[1]*E(4));
            od;

        # primes $p = 3$ mod 4 stay prime
        else
            while IsCycInt( x / prm )  do
                Add( facs, prm );
                x := x / prm;
            od;
        fi;

    od;

    # the first factor takes the unit
    if not x in [ 1, -1, E(4), -E(4) ]  then
        Error("Panic: 'GaussianIntegersOps.Factors' cofactor is not a unit");
    fi;
    facs[1] := x * facs[1];

    # return the result
    return facs;
end;


#############################################################################
##
#F  GaussianIntegersOps.AsGroup(<GaussInt>) . . .  Gaussian integers as group
##
GaussianIntegersOps.AsGroup := function ( GaussInt )
    Error("sorry, Z[I] is not finitely generated as multiplicative group");
end;


#############################################################################
##
#F  GaussianIntegersOps.AsAdditiveGroup(<GaussInt>) . . . . Gaussian integers
#F                                                          as additive group
##
#N  14-Oct-91 martin this should be
#N  GaussianIntegersAsAddtiveGroupOps := Copy( AdditveGroupOps );
##
GaussianIntegersAsAdditiveGroupOps := OperationsRecord(
              "GaussianIntegersAsAdditiveGroupOps", DomainOps );

GaussianIntegersOps.AsAdditiveGroup := function ( GaussInt )

    return rec(
        isDoman                 := true,
        isAdditiveGroup         := true,

        generators              := [ 1, E(4) ],
        zero                    := 0,

        size                    := "infinity",
        isFinite                := true,

        operations              := GaussianIntegersAsAdditiveGroupOps
    );

end;


#############################################################################
##
#F  IsGaussRat( <x> ) . . . . . . .  test if an object is a Gaussian rational
##
##  'IsGaussRat' returns 'true' if the  object <x> is a Gaussian rational and
##  'false' otherwise.  Gaussian rationals are of the form '<a> + <b>\*E(4)',
##  where <a> and <b> are rationals.
##
IsGaussRat := function ( x )
    return IsCyc( x ) and (NofCyc( x ) = 1 or NofCyc( x ) = 4);
end;


#############################################################################
##
#V  GaussianRationals . . . . . . . . . . . . . . field of Gaussian rationals
#V  GaussianRationalsOps  . . . . .  operations record for Gaussian rationals
##
GaussianRationalsOps := OperationsRecord( "GaussianRationalsOps",
                                          CyclotomicFieldOps );

GaussianRationals := rec(
    isDomain                    := true,
    isField                     := true,
    isCyclotomicField           := true,

    char                        := 0,
    generators                  := [ 1, E(4) ],
    zero                        := 0,
    one                         := 1,
    name                        := "GaussianRationals",
    stabilizer                  := [ 1 ],

    size                        := "infinity",
    isFinite                    := false,
    degree                      := 2,

    field                       := Rationals,
    dimension                   := 2,
    base                        := [ 1, E(4) ],
    isIntegralBase              := true,
    zumbroichbase               := [ 0, 1 ],
    automorphisms               := [ x -> x, x -> GaloisCyc(x,-1) ],

    operations                  := GaussianRationalsOps
);


#############################################################################
##
#F  GaussianRationalsOps.Ring(<elms>) . . . . . . . .  ring generated by some
#F                                                         Gaussian rationals
##
GaussianRationalsOps.Ring := function ( elms )
    if ForAll( elms, IsInt )  then
        return Integers;
    elif ForAll( elms, IsCycInt )  then
        return GaussianIntegers;
    else
        return AsRing( GaussianRationals );
    fi;
end;


#############################################################################
##
#F  GaussianRationalsOps.DefaultRing(<elms>)   default ring generated by some
#F                                                         Gaussian rationals
##
GaussianRationalsOps.DefaultRing := function ( elms )
    if ForAll( elms, IsInt )  then
        return Integers;
    elif ForAll( elms, IsCycInt )  then
        return GaussianIntegers;
    else
        return AsRing( GaussianRationals );
    fi;
end;


#############################################################################
##
#F  GaussianRationalsOps.Random(<GaussRat>) . . . .  random Gaussian rational
##
##  'GaussianRationalsOps.Random'  returns a random Gaussian rational.
##
GaussianRationalsOps.Random := function ( GaussRat )
    return Random(Rationals) + Random(Rationals) * E(4);
end;


#############################################################################
##
#F  GaussianRationalsOps.Automorphisms(<GaussRat>)  . . . . . . automorphisms
#F                                                  of the Gaussian rationals
##
GaussianRationalsOps.Automorphisms := function ( GaussRat )
    return [ x -> x, x -> GaloisCyc( x, -1 ) ];
end;


#############################################################################
##
#F  GaussianRationalsOps.Conjugates(<GaussRat>,<x>) . . . . . . .  conjugates
#F                                                     of a Gaussian rational
##
##  'GaussianRationals.Conjugates' returns  the  list of  conjugates   of the
##  Gaussian      rational   <x>.  I.e.,   if    '<x> =   <a> +   <b>\*E(4)',
##  'GaussianRationals.Conjugates' returns the list '[ <a> + <b>\*E(4), <a> -
##  <b>\*E(4) ]'.   Note that  the list will contain  <x>  twice if <x>  is a
##  rational.
##
GaussianRationalsOps.Conjugates := function ( GaussRat, x )
    return [ x, GaloisCyc( x, -1 ) ];
end;


#############################################################################
##
#F  GaussianRationalsOps.Norm(<GaussRat>,<x>) . . norm of a Gaussian rational
##
##  'GaussianRationalsOps.Norm' returns  the  norm  of the  Gaussian rational
##  <x>.  The norm is the product of <x> with its  conjugate, i.e., if '<x> =
##  <a> + <b>\*E(4)', the norm is $a^2 + b^2$.  The  norm is rational, and is
##  an integer if <x> is a Gaussian integer.
##
GaussianRationalsOps.Norm := function ( GaussRat, x )
    return x * GaloisCyc( x, -1 );
end;


#############################################################################
##
#F  GaussianRationalsOps.Trace(<GaussRat>,<x>) . trace of a Gaussian rational
##
##  'GaussianRationalsOps.Trace' returns the  trace of  the Gaussian rational
##  <x>.  The trace is the sum of <x> with its conjugate, i.e., if '<x> = <a>
##  +   <b>\*E(4)', the trace is  $2a$.   The trace  is  rational, and  is an
##  integer if <x> is a Gaussian integer.
##
GaussianRationalsOps.Trace := function ( GaussRat, x )
    return x + GaloisCyc( x, -1 );
end;


#############################################################################
##
#F  GaussianRationalsOps.CharPol(<GaussRat>,<x>)  . .  characteristic polynom
#F                                                     of a Gaussian rational
##
GaussianRationalsOps.CharPol := function ( GaussRat, x )
    return [ x * GaloisCyc(x,-1), -x-GaloisCyc(x,-1), 1 ];
end;


#############################################################################
##
#F  GaussianRationalsOps.MinPol(<GaussRat>,<x>) . . . . . . . minimal polynom
#F                                                     of a Gaussian rational
##
GaussianRationalsOps.MinPol := function ( GaussRat, x )
    if IsRat( x )  then
        return [ -x, 1 ];
    else
        return [ x * GaloisCyc(x,-1), -x-GaloisCyc(x,-1), 1 ];
    fi;
end;


#############################################################################
##
#F  GaussianRationalsOps.AsGroup(<GaussRat>)  . . view the Gaussian rationals
#F                                                    as multiplicative group
##
GaussianRationalsOps.AsGroup := function ( GaussRat )
    Error("sorry, Q[I] is not finitely generated as multiplicative group");
end;


#############################################################################
##
#F  GaussianRationalsOps.AsAdditiveGroup(<GaussRat>)  . . . view the Gaussian
#F                                                rationals as additive group
##
GaussianRationalsOps.AsAdditiveGroup := function ( GaussRat )
    Error("sorry, Q[I] is not finitely generated as additive group");
end;


#############################################################################
##
#F  GaussianRationalsOps.AsRing(<GaussRat>) . . . view the Gaussian rationals
#F                                                                    as ring
##
#N  23-Oct-91 martin this should be 'FieldOps.AsRing'
##
GaussianRationalsAsRingOps := OperationsRecord(
                "GaussianRationalsAsRingOps", RingOps );

GaussianRationalsAsRingOps.\in := GaussianRationalsOps.\in;

GaussianRationalsAsRingOps.Random := GaussianRationalsOps.Random;

GaussianRationalsAsRingOps.Quotient := function ( R, r, s )
    return r/s;
end;

GaussianRationalsAsRingOps.IsUnit := function ( R, r )
    return r <> R.zero;
end;

GaussianRationalsAsRingOps.Units := function ( R )
    return AsGroup( R.field );
end;

GaussianRationalsAsRingOps.IsAssociated := function ( R, r, s )
    return (r = R.zero) = (s = R.zero);
end;

GaussianRationalsAsRingOps.StandardAssociate := function ( R, r )
    if r = R.zero  then
        return R.zero;
    else
        return R.zero;
    fi;
end;

GaussianRationalsOps.AsRing := function ( GaussRat )

    return rec(
        isDomain                := true,
        isRing                  := true,

        zero                    := 0,
        one                     := 1,

        isFinite                := false,
        size                    := "infinity",
        isCommutativeRing       := true,
        isIntegralRing          := true,
        field                   := GaussRat,

        operations              := GaussianRationalsAsRingOps
    );
end;


#############################################################################
##
#E  Emacs . . . . . . . . . . . . . . . . . . . . . . . local emacs variables
##
##  Local Variables:
##  mode:               outline
##  outline-regexp:     "#F\\|#V\\|#E"
##  fill-column:        73
##  fill-prefix:        "##  "
##  eval:               (hide-body)
##  End:
##



