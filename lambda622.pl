#!/usr/local/bin/perl -w

my $progname = "Pure lambda calculus in Perl, v0.622";

# - substitution occurs at run-time instead of statically
# - function application by juxtaposition w/o parentheses
# - parentheses used for grouping only
# - function definitions in curried form
# - more descriptive error messages by using exception handling
# - simplified application notation in the intermediate reduction messages

# ToDo:
# - multi-line expressions and definitions
# - if ... then ... else



my ($exp, $app, $pap);
$exp = qr{ (?>[^() ]+) (??{$pap})? | (??{$pap}) }x;
$app = qr{ (??{$exp}) (?:\ (??{$exp}))+ }x;
$pap = qr{ \( ( (??{$app}) ) \) }x;

my %def = ( # default macro definitions
  identity => 'x.x',
  id => 'x.x',

  true => 'x.y.x',
  false => 'x.y.y',
  not => 'x.(x false true)',
  and => 'x.y.(x y false)',
  or => 'x.y.(x true y)',

  zero => 'x.x',
  succ => 'n.s.(s false n)',
  iszero => 'n.(n true)',
  one => '(succ zero)',
  two => '(succ one)',
  three => '(succ two)',
  four => '(succ three)',
  five => '(succ four)',
  six => '(succ five)',
  seven => '(succ six)',
  eight => '(succ seven)',
  nine => '(succ eight)',
  ten => '(succ nine)',
  pred => 'n.((iszero n) zero (n false))',

  add => 'x.y.((iszero x) y (add (pred x) (succ y)))',
    # recursion through definition is possible!
);

#sub evaluate
#{
#  my $form;
#
#  ($_, $form) = @_;
#
#  if ( /^\w+$/ ) {
#    if ( exists $def{$_} ) {
#      return $_;
#    } else {
#      die "free variables not allowed!\n";
#    }
#  }
#
#  return $_ if /^\w+\.$exp$/; # function evaluates to itself
#
#  return reduce($1, $form) if /^$pap$/;
#
#  return reduce($_, $form) if /^$app$/;
#
#  die "syntax error!\n";
#}

sub expand # only if possible
{
  my ($expr, $form) = @_;

  # multi-time macro expansion engine
  while ( $expr =~ /^\w+$/ && exists $def{$expr} ) {
    $expr = $def{$expr};
    printf "== $form\n", $expr if $form;
  }

  return $expr;
}


sub expand_and_evaluate
{
  my $form;

  ($_, $form) = @_;

  if ( /^\w+$/ ) # for a single name
  {
    if ( $form eq '%s' )
    {
      # returns it without further macro expansion if we are at the top-level
      return $_ if exists $def{$_};
    }
    else
    {
      $_ = expand($_, $form);
    }

    die "free variable '$_' not allowed!\n" if /^\w+$/;
  }

  return $_ if /^\w+\.$exp$/; # function evaluates to itself

  return reduce($1, $form) if /^$pap$/;
    # peels off the parentheses and applies reduction

  return reduce($_, $form) if /^$app$/;

  die "syntax error!\n";
}

sub reduce
{
  my ($expr, $form) = @_;

  # syntax already checked at evaluate()

  # syntactic sugaring here...

  my ($func, $arg1, @argv) = $expr =~ /$exp/g; # separates all subexpressions
    # the syntax check above guarantees that $func and $arg1 are nonempty
  #my $iform = sprintf $form, @argv ? "(%s $arg1 @argv)" : "(%s $arg1)";
  my $iform = sprintf $form, @argv ? "%s $arg1 @argv" : "%s $arg1"; # intermediate form
    # note that the left-most opening parentheses in an expression are not actually needed
    # sprintf works well even if $form is empty

  # evaluation of the function expression
  $func = expand_and_evaluate($func, $iform);

  # parse bound variable and function's body
  my ($name, $body) = function($func, $iform);

  # we could also peel off the outer-most parentheses from the body expression
  #$body = $1 if $body =~ /^$pap$/;

  # evaluation of the argument expression if in pass-by-value semantics
  #$arg1 = evaluate($arg1, ...);

  # normal order beta-reduction
  my @slip = $body =~ /\b$name\.$exp/g;
    # collects those nested functions which have $name as its bound variable
  $body =~ s/\b$name\.$exp/%s/g;
    # and punches out them marking with %s as a placeholder
  $body =~ s/\b$name\b/$arg1/g; # how cool a function application can be!
    # all variables named $name are now free, so replace them at no risk
  $body = sprintf $body, @slip if @slip;
    # restores those punch-outs back to $body
  #$iform = @argv ? sprintf $form, "(%s @argv)" : $form;
  $iform = @argv ? sprintf $form, "%s @argv" : $form;
  printf "=> $iform\n", $body if $iform;
    # displays the reduction

  # evaluation of the function body expression
  $func = expand_and_evaluate($body, $iform);
    # here $_ gets the result of the last evaluation

  # further evaluation if needed
  return @argv ? reduce("$func @argv", $form) : $_; # tail-recursive
}

sub function
{
  my ($expr, $form) = @_;
  my ($name, $body);

  die "illegal function expression\n"
    unless ($name, $body) = $expr =~ /^(\w+)\.($exp)$/;

  return wantarray ? ($name, $body) : $expr;
}

sub define # or compile
# static macro expansion is not supported, so we are not doing any expansion here
{
  my ($expr, $form) = @_;
  my ($name, $vars, $func);

  # syntax check
  die "syntax error!\n"
    unless ($name, $vars, $func) =
      $expr =~ /^def (\w+) ((?:\w+ )*)=\s?($exp((?: $exp)*))$/;

  # if function's body is an application, then parenthesize it
  $func = "($func)" if $4;

  $_ = $def{$name} = join '.', split(' ', $vars), $func;
  print "$name := $_\n";

  return $_;
}



print "$progname\n\n- ";

while (<>)
{
  chomp;

  last if /^\s*$/; # exits loop if blank line

  eval
  {
    if ( /^def / ) {
      define($_, '%s');
    } else {
      expand_and_evaluate($_, '%s');
    }
    print "done.\n";
  };

  print "$@- "; # prints error message if any
}
