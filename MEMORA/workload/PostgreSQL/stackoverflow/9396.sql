
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
),
BadgeStats AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
MergedStats AS (
    SELECT 
        u.UserId,
        u.Reputation,
        u.PostCount,
        u.QuestionsCount,
        u.AnswersCount,
        u.UpVotesCount,
        u.DownVotesCount,
        COALESCE(b.GoldBadges, 0) AS GoldBadges,
        COALESCE(b.SilverBadges, 0) AS SilverBadges,
        COALESCE(b.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserStats u
    LEFT JOIN 
        BadgeStats b ON u.UserId = b.UserId
)
SELECT 
    UserId,
    Reputation,
    PostCount,
    QuestionsCount,
    AnswersCount,
    UpVotesCount,
    DownVotesCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    (QuestionsCount * 3 + AnswersCount * 2 + UpVotesCount * 1 - DownVotesCount * 1) AS Score
FROM 
    MergedStats
WHERE 
    Reputation > 1000
ORDER BY 
    Score DESC
FETCH FIRST 10 ROWS ONLY;
