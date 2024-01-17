function life_ = GA_reverse(life)
    r1 = randperm(length(life.fc),1);
    r2 = randperm(length(life.fc),1);
    mininverse = min([r1, r2]);
    maxinverse = max([r1, r2]);
    life.fc(mininverse: maxinverse) = life.fc(maxinverse: -1: mininverse);
    life_ = life;
end