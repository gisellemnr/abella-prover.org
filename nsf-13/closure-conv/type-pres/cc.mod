module cc.

is_nat z.
is_nat (s N) :- is_nat N.

% Some generic predicates
tl_member X (tl_cons X L).
tl_member X (tl_cons Y L) :- tl_member X L.

ml_member X (ml_cons X L).
ml_member X (ml_cons Y L) :- ml_member X L.

mapvar tl_nil X ml_nil.
mapvar (tl_cons X L) Env (ml_cons (map X (fst Env)) LMap) :-
     mapvar L (rst Env) LMap.

mapenv tl_nil _ unit.
mapenv (tl_cons X L) Map (cross M ML) :-
       ml_member (map X M) Map, mapenv L Map ML.

combine tl_nil Fvs2 Fvs2.
combine (tl_cons X Fvs1) Fvs2 Fvs :-
      tl_member X Fvs2, combine Fvs1 Fvs2 Fvs.
combine (tl_cons X Fvs1) Fvs2 (tl_cons X Fvs) :-
      combine Fvs1 Fvs2 Fvs.

% free variables in a term; second argument is the list of candidates
fvars X _ tl_nil :- notfree X.
fvars (cst C) _ tl_nil.
fvars (lnat _) _ tl_nil.
fvars Y Vs (tl_cons Y tl_nil) :- tl_member Y Vs.
fvars (app M1 M2) Vs CFvs :-
   fvars M1 Vs Fvs1, fvars M2 Vs Fvs2, combine Fvs1 Fvs2 CFvs.
fvars (abs M) Vs Fvs :- pi y\ notfree y => fvars (M y) Vs Fvs.

cc X M Map FVs :- ml_member (map X M) Map.
cc (lnat N) (clnat N) Map FVs.
cc (abs M) (cpair (cabs x\ (clet (fst x)
				 (y\ (clet (rst x) xenv\ (P xenv y)))))
		  PE) Map FVs :-
   fvars (abs M) FVs NFVs,
   mapenv NFVs Map PE,
   (pi xenv\
	     mapvar NFVs xenv (NMap xenv)),
   (pi x\ pi y\ pi xenv\
	     cc (M x) (P xenv y) (ml_cons (map x y) (NMap xenv)) (tl_cons x NFVs)).
cc (app M1 M2) (cunpair CM1
			(f\ env\ (capp f (cross CM2 env)))) Map FVs :-
   cc M1 CM1 Map FVs, cc M2 CM2 Map FVs.
cc (cst C) (ccst C) Map FVs.
cc' X M :- cc X M ml_nil tl_nil.


term (app (app (abs x\ (abs y\ (app (app (cst s++) x) y))) (lnat z)) (lnat (s z))).


% Definition of the typing relation for lambda terms.
of (lnat _) nat_t.
of (cst C) T :- of_const C T.
of (app M N) T :- of M (arr T1 T), of N T1.
of (abs M) (arr T1 T2) :- pi x\ of x T1 => of (M x) T2.

of_const s++ (arr nat_t (arr nat_t nat_t)).

% Definition of the typing relation for closure converted terms.
cof (clnat _) nat_t.
cof (ccst C) T :- cof_const C T.
cof (clet M1 M2) T :-
    cof M1 T1,
    (pi x\ cof x T1 => cof (M2 x) T).
cof unit unit_t.
cof (cross M1 M2) (product T1 T2) :- cof M1 T1, cof M2 T2.
cof (fst M) T1 :- cof M (product T1 T2).
cof (rst M) T2 :- cof M (product T1 T2).
cof (capp M N) T :- cof M (code T1 T), cof N T1.
cof (cabs M) (code T1 T2) :- pi x\ cof x T1 => cof (M x) T2.
cof (cpair P Q) (arr T1 T2) :-
    cof P (code (product T1 TL) T2),
    cof Q TL.
cof (cunpair P Q) T :-
    cof P (arr T1 T),
    (pi f\ pi env\ pi l\
	cof f (code (product T1 l) T) =>
	cof env l =>
	cof (Q f env) T).

cof_const (s++) (arr nat_t (arr nat_t nat_t)).
