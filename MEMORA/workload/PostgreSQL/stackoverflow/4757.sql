
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(COALESCE(v.BountyAmount, 0)) DESC) AS BountyRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9  
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounties,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
    WHERE PostCount > 0
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.Reputation,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.TotalBounties,
    COALESCE(ROUND((CAST(t.TotalBounties AS decimal) / NULLIF(t.PostCount, 0)), 2), 0) AS AvgBountyPerPost,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = t.UserId AND b.Class = 1) AS GoldBadges,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = t.UserId AND b.Class = 2) AS SilverBadges,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = t.UserId AND b.Class = 3) AS BronzeBadges,
    CASE 
        WHEN t.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN t.ReputationRank <= 50 THEN 'Valued Member'
        ELSE 'Novice'
    END AS UserCategory
FROM TopUsers t
WHERE t.TotalBounties IS NOT NULL
ORDER BY t.Reputation DESC, t.TotalBounties DESC
LIMIT 50;
