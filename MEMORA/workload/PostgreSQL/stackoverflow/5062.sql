WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(b.Class) AS TotalBadges,
        MAX(p.CreationDate) AS LastPostDate,
        CUME_DIST() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        CommentCount,
        TotalBadges,
        LastPostDate,
        ReputationRank
    FROM 
        UserStatistics
    WHERE 
        PostCount > 0
    ORDER BY 
        ReputationRank
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.CommentCount,
    tu.TotalBadges,
    tu.LastPostDate,
    COUNT(DISTINCT CASE WHEN ph.PostId IS NOT NULL THEN ph.Id END) AS PostHistoryCount
FROM 
    TopUsers tu
LEFT JOIN 
    PostHistory ph ON tu.UserId = ph.UserId
GROUP BY 
    tu.DisplayName, tu.Reputation, tu.PostCount, tu.QuestionCount, tu.AnswerCount, tu.CommentCount, tu.TotalBadges, tu.LastPostDate
ORDER BY 
    tu.Reputation DESC;
