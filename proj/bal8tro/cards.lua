suit_colors=split"1,8,3,9"
rank_names="23456789tjqka"

function new_deck(spec)
 local deck={}
 for suit=1,4 do
  for rank=2,14 do
   local card={rank=rank,suit=spec and spec.suits==2 and (suit-1)%2+1 or suit}
   if not (spec and spec.faces==0 and is_face(card)) then add(deck,card) end
  end
 end
 return deck
end

function shuffled(cards)
 local deck={}
 for card in all(cards) do
  card.glide_x,card.picked,card.flip=nil
  add(deck,card)
 end
 for i=#deck,2,-1 do
  local j=flr(rnd(i))+1
  deck[i],deck[j]=deck[j],deck[i]
 end
 return deck
end

function card_chips(card)
 return card.rank==14 and 11 or min(card.rank,10)
end

function is_face(card)
 return card.rank>10 and card.rank<14
end

function is_suit(card,suit)
 return card.suit==suit or card.enhancement=="wild"
end

function sort_cards(cards,by_suit)
 local function key(card)
  return by_suit and card.suit*16+card.rank or card.rank*4+card.suit
 end
 for i=2,#cards do
  local j=i
  while j>1 and key(cards[j])>key(cards[j-1]) do
   cards[j],cards[j-1]=cards[j-1],cards[j]
   j-=1
  end
 end
end

function evaluate(played)
 local counts,most,pair_count,distinct,low,high={},0,0,0,15,0
 for card in all(played) do
  counts[card.rank]=(counts[card.rank] or 0)+1
  low,high=min(low,card.rank),max(high,card.rank)
 end
 for rank,count in pairs(counts) do
  distinct+=1
  most=max(most,count)
  if count>=2 then pair_count+=1 end
 end
 local flush
 for suit=1,#played\5*4 do
  local same=true
  for card in all(played) do same=same and is_suit(card,suit) end
  flush=flush or same
 end
 local straight=distinct==5 and (high-low==4 or counts[14] and counts[5] and low==2)
 local contains={
  high=true,pair=most>=2,two=pair_count>=2,three=most>=3,
  straight=straight,flush=flush,full=most==3 and pair_count==2,
  four=most>=4,sflush=straight and flush
 }
 local spec
 for candidate in all(hand_specs) do
  if contains[candidate.name] then spec=candidate end
 end
 local scoring={}
 for card in all(played) do
  if straight or flush or spec.name=="full" or counts[card.rank]>=2 then add(scoring,card) end
 end
 if spec.name=="high" then
  for card in all(played) do
   if card.rank==high then scoring={card} break end
  end
 end
 local label=spec.label
 if contains.sflush and low==10 then label="royal flush" end
 return spec,scoring,contains,label
end
