
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.Score > 0 THEN p.Id END) AS PositivePosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionsCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswersCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
Ranking AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        PostCount,
        PositivePosts,
        QuestionsCount,
        AnswersCount,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStats
),
TopUsers AS (
    SELECT 
        * 
    FROM 
        Ranking
    WHERE 
        UserRank <= 10
)

SELECT 
    t.DisplayName,
    t.Reputation,
    t.GoldBadges,
    t.SilverBadges,
    t.BronzeBadges,
    t.PostCount,
    t.PositivePosts,
    (t.QuestionsCount * 1.0 / NULLIF(t.PostCount, 0)) AS QuestionRatio,
    (t.AnswersCount * 1.0 / NULLIF(t.PostCount, 0)) AS AnswerRatio,
    ps.TotalVotes
FROM 
    TopUsers t
LEFT JOIN (
    SELECT 
        v.UserId, 
        COUNT(v.Id) AS TotalVotes 
    FROM 
        Votes v 
    GROUP BY 
        v.UserId
) ps ON t.UserId = ps.UserId
WHERE 
    (t.GoldBadges + t.SilverBadges + t.BronzeBadges) > 0
ORDER BY 
    t.Reputation DESC;
