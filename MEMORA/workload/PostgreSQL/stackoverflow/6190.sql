WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        AVG(v.BountyAmount) AS AvgBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        WikiCount,
        AvgBounty,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC, PostCount DESC) AS ReputationRank
    FROM 
        UserStats
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.PostCount,
    ru.QuestionCount,
    ru.AnswerCount,
    ru.WikiCount,
    COALESCE(ru.AvgBounty, 0) AS AvgBounty,
    ru.BadgeCount,
    pt.Name AS PostType
FROM 
    RankedUsers ru
JOIN 
    PostTypes pt ON ru.PostCount > 0
WHERE 
    ru.ReputationRank <= 10
ORDER BY 
    ru.Reputation DESC, ru.PostCount DESC;