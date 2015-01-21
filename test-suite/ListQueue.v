Require Import Parametricity.

Require Import List.
Import ListNotations.

Record Queue := {
  t :> Type;
  empty : t;
  push : nat -> t -> t;
  pop : t -> option (nat * t) 
}.

Definition bind_option {A B} (f : A -> option B) (x : option A) : option B := 
  match x with 
   | Some x => f x
   | None => None
  end.

Notation "'do' X <- A 'in' B" := (bind_option (fun X  => B) A)
 (at level 200, X ident, A at level 100, B at level 200).

Definition bind_option2 {A B C} (f : A -> B -> option C) (x : option (A * B)) : option C := 
  do yz <- x in let (y, z) := yz : A * B in f y z.

Notation "'do' X , Y   <- A 'in' B" := (bind_option2 (fun X Y => B) A)
 (at level 200, X ident, Y ident, A at level 100, B at level 200).

Definition program (Q : Queue) (n : nat) : option nat :=
   (* q := 0::1::2::...::n *)
   let q : Q := 
     nat_rect (fun _ => Q) Q.(empty) Q.(push) (S n)
   in 
   let q : option Q := nat_rect (fun _ => option Q) (Some q)
     (fun _ (q : option Q) => 
         do q <- q in
         do x, q <- Q.(pop) q in
         do y, q <- Q.(pop) q in
         Some (Q.(push) (x + y) q)) n 
   in 
   do q <- q in 
   option_map fst (Q.(pop) q).
      
Require Import List.

Definition ListQueue := {|
  t := list nat; 
  empty := nil; 
  push := @cons nat;
  pop := fun l => 
    match rev l with
      | nil => None 
      | hd :: tl => Some (hd, rev tl) end
|}.

Definition DListQueue := {|
  t := list nat * list nat; 
  empty := (nil, nil);
  push x l := 
    let (back, front) := l in 
    (cons x back,front);
  pop := fun l =>
    let (back, front) := l in 
    match front with 
      | [] => 
         match rev back with
            | [] => None
            | hd :: tl => Some (hd, (nil, tl))
         end
      | hd :: tl => Some (hd, (back, tl))
    end
|}.


Lemma nat_R_equal : 
  forall x y, nat_R x y -> x = y.
intros x y H; induction H; subst; trivial.
Defined.

Lemma equal_nat_R : 
  forall x y, x = y -> nat_R x y.
intros x y H; subst.
induction y; constructor; trivial.
Defined.

Lemma option_nat_R_equal : 
  forall x y, option_R nat nat nat_R x y -> x = y.
intros x1 x2 H; destruct H as [x1 x2 x_R | ].
rewrite (nat_R_equal _ _ x_R); reflexivity.
reflexivity.
Defined.

Lemma equal_option_nat_R : 
  forall x y, x = y -> option_R nat nat nat_R x y.
intros x y H; subst.
destruct y; constructor; apply equal_nat_R; reflexivity.
Defined.

Translate Inductive Queue.
Translate @bind_option.
Translate @bind_option2.
Translate t.
Translate empty.
Translate push.
Translate pop.

Notation Bisimilar := Queue_R.
Print Queue_R.


Definition R (l1 : list nat) (l2 : list nat * list nat) :=
 let (back, front) := l2 in 
  l1 = back ++ rev front.

Lemma rev_app : 
  forall A (l1 l2 : list A), 
    rev (l1 ++ l2) = rev l2 ++ rev l1.
induction l1.
intro; symmetry; apply app_nil_r.
intro; simpl; rewrite IHl1; rewrite app_ass.
reflexivity.
Defined.

Lemma rev_list_rect A  :
      forall P:list A-> Type,
	P [] ->
	(forall (a:A) (l:list A), P (rev l) -> P (rev (a :: l))) ->
	forall l:list A, P (rev l).
Proof.
  induction l; auto.
Defined.

Theorem rev_rect A :
  forall P:list A -> Type,
	P [] ->
	(forall (x:A) (l:list A), P l -> P (l ++ [x])) -> forall l:list A, P l.
Proof.
  intros.
  generalize (rev_involutive l).
  intros E; rewrite <- E.
  apply (rev_list_rect _ P).
  auto.

  simpl.
  intros.
  apply (X0 a (rev l0)).
  auto.
Defined.


Lemma bisim_list_dlist : Bisimilar ListQueue DListQueue.
apply (Build_Queue_R _ _ R).

* reflexivity.

* intros n1 n2 n_R.
pose (nat_R_equal _ _ n_R) as H.
destruct H. clear n_R.
intros l [back front].
unfold R.
simpl.
intro; subst.
simpl.
reflexivity.

* intros l  [back front].
generalize l. clear l.
unfold R; fold R.
pattern back.

apply rev_rect.

intros l H; subst.
rewrite rev_app.
simpl.
rewrite app_nil_r.
rewrite rev_involutive.

destruct front.
constructor.
repeat constructor.
apply equal_nat_R; reflexivity.

clear back; intros hd back IHR l H.
subst.
rewrite rev_app.
rewrite rev_involutive.
rewrite rev_app.
simpl.
destruct front.
simpl.
repeat constructor.
apply equal_nat_R; reflexivity.
simpl.
repeat constructor.
apply equal_nat_R; reflexivity.
unfold R.
rewrite rev_app.
simpl.
rewrite rev_involutive.
reflexivity.
Qed.

Print eq_R.

Translate program.
Print program_R.

Lemma program_independent : 
 forall n, 
  program ListQueue n = program DListQueue n.
intro n.
apply option_nat_R_equal.
apply program_R.
apply bisim_list_dlist.
apply equal_nat_R.
reflexivity.
Defined.


