WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(b.Class) AS TotalBadgeScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
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
        CommentCount,
        TotalBadgeScore,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank
    FROM 
        UserStats
),
TopUsers AS (
    SELECT 
        *, 
        GREATEST(ReputationRank, PostCountRank) AS OverallRank
    FROM 
        RankedUsers
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.CommentCount,
    tu.TotalBadgeScore,
    tu.OverallRank,
    COUNT(DISTINCT v.Id) AS VoteCount,
    SUM(v.BountyAmount) AS TotalBounty
FROM 
    TopUsers tu
LEFT JOIN 
    Votes v ON v.UserId = tu.UserId
GROUP BY 
    tu.UserId, tu.DisplayName, tu.Reputation, tu.PostCount, 
    tu.QuestionCount, tu.AnswerCount, tu.CommentCount, 
    tu.TotalBadgeScore, tu.OverallRank
ORDER BY 
    tu.OverallRank, tu.Reputation DESC;
