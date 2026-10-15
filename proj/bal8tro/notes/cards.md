# cards.lua

**cards.lua:1** `suit_colors=split"1,8,3,9"`
Suits are 1 spade, 2 heart, 3 club, 4 diamond; four colours (Balatro's high-contrast deck) so suits read at a glance. Sprites 1..4 are big suits, 17..20 small.

**cards.lua:2** `rank_names=split("2,3,4,5,6,7,8,9,10,j,q,k,a",",",false)`
Ranks are 2..14, ace high; rank_names is indexed rank-1.

**cards.lua:12** `function shuffled(cards)`
A shuffled list of the same card tables (not copies), with each one's place on screen, pick and flip cleared, so it is dealt from the deck again. Anything else on a card (its suit, rank, an enhancement) lasts.
Keep: tests/test_hands.lua checks a changed card survives two shuffles.

**cards.lua:33** `function sort_cards(cards,by_suit)`
Insertion sort, highest first, by rank (suit breaks ties) or by suit then rank.

**cards.lua:46** `function evaluate(played)`
Takes 1..5 cards; returns the hand spec, the cards that score, the contains table and the label. Straights and flushes need five cards; A-2-3-4-5 is a straight, Q-K-A-2-3 is not. High card scores only its highest card; pair/two/three/four score the cards in groups; straight, flush, full house and straight flush score all five.
Keep: tests/test_hands.lua checks every hand type and its scoring count.
