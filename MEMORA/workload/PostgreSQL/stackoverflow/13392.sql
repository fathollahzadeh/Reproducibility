WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(v.BountyAmount) AS TotalBountyAmount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY u.Id
),

TopUsers AS (
    SELECT 
        UserId,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalCommentScore,
        TotalBountyAmount,
        AvgReputation,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserStats
)

SELECT 
    u.DisplayName,
    u.Reputation,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.TotalCommentScore,
    t.TotalBountyAmount,
    t.AvgReputation,
    t.Rank
FROM 
    TopUsers t
JOIN Users u ON t.UserId = u.Id
WHERE 
    t.Rank <= 10
ORDER BY 
    t.Rank;