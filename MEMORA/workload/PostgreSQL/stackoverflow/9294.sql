
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS TotalGoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS TotalSilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS TotalBronzeBadges,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        us.UserId, 
        us.DisplayName,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAcceptedAnswers,
        us.TotalGoldBadges,
        us.TotalSilverBadges,
        us.TotalBronzeBadges,
        us.ReputationRank
    FROM 
        UserStatistics us
    WHERE 
        us.TotalPosts > 0
    ORDER BY 
        us.ReputationRank
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.TotalQuestions,
    tu.TotalAcceptedAnswers,
    tu.TotalGoldBadges,
    tu.TotalSilverBadges,
    tu.TotalBronzeBadges,
    tu.ReputationRank,
    COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS TotalCloseVotes,
    COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 ELSE 0 END), 0) AS TotalSuggestedEdits
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    tu.DisplayName, tu.TotalQuestions, tu.TotalAcceptedAnswers, 
    tu.TotalGoldBadges, tu.TotalSilverBadges, tu.TotalBronzeBadges, 
    tu.ReputationRank
ORDER BY 
    tu.ReputationRank;
