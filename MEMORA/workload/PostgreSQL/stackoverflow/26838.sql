WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(v.VoteTypeId) AS AverageVoteType
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
)

SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.ReputationRank,
    ru.PostCount,
    ru.AnswerCount,
    ru.QuestionCount,
    ru.AverageVoteType,
    bh.BadgeCount
FROM 
    RankedUsers ru
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) bh ON ru.UserId = bh.UserId
WHERE 
    ru.ReputationRank <= 10
ORDER BY 
    ru.Reputation DESC, ru.DisplayName;