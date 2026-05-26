#include <stdio.h>
#include <stdlib.h>

#define SYNTAX_ERROR() \
	fprintf(stderr, "syntax error"); \
	exit(1)

enum terminals {
	PLUS,
	MINUS,
	A,
	OPEN_PARENTHESIS,
	CLOSE_PARENTHESIS,
	ZERO,
	ONE
};

enum terminals lookahead;

void match(enum terminals t) {
	if(lookahead == t) {
		// lookahead = next;
		return;
	}
	SYNTAX_ERROR();
}

// S -> + S S | - S S | a
void S1() {
	switch(lookahead) {
	case PLUS:
		match(PLUS); S1(); S1();
		break;
	case MINUS:
		match(MINUS); S1(); S1();
		break;
	case A:
		match(A);
		break;
	default:
		SYNTAX_ERROR();
	}
}

// S -> S (S) S | empty
//
// S = A
// alfa = (S) S
// beta = empty
//
// S -> beta R
// R -> alfa R | empty
//
// S -> R
// R -> (S) S R | empty
//
// Since S can only have the form of R, maybe the only production in this
// grammar is:
//
// R -> (R) R R | empty
void S2() {
	switch(lookahead) {
	case OPEN_PARENTHESIS:
		match(OPEN_PARENTHESIS); S2(); match(CLOSE_PARENTHESIS); S2(); S2();
		break;
	default:
		// No syntax error since R -> empty is a production
		break;
	}
}

// S -> 0 S 1 | 0 1
//
// Essas produções vão contra a regra que diz:
//
// "The FIRST sets must be considered if there are two productions
// A -> alfa and A -> beta. Ignoring empty productions for the moment,
// predictive parsing requires FIRST(alfa) and FIRST(beta) to be disjoint."
//
// Já que nesse caso alfa = 0 S 1 e beta = 0 1, então
// FIRST(alfa) == FIRST(beta) == 0
//
// Mesmo assim, vale uma tentativa:
void S3() {
	switch(lookahead) {
		case ZERO:
			match(ZERO);
			if(lookahead != ONE) {
				S3();
			}
			match(ONE);
			break;
		default:
			SYNTAX_ERROR();
	}
}
