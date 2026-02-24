WITH RECURSIVE UserReputation AS (
    
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),
TopUsers AS (
    
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        ReputationRank
    FROM 
        UserReputation
    WHERE 
        ReputationRank <= 10
),
PostDetails AS (
    
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM 
        Posts p
    WHERE 
        p.OwnerUserId IN (SELECT UserId FROM TopUsers)
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.ReputationRank,
    pd.TotalPosts,
    pd.TotalQuestions,
    pd.TotalAnswers,
    pd.TotalViews,
    pd.TotalScore,
    COALESCE(BadgeCount.TotalBadges, 0) AS TotalBadges
FROM 
    TopUsers tu
LEFT JOIN 
    PostDetails pd ON tu.UserId = pd.OwnerUserId
LEFT JOIN (
    
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS TotalBadges
    FROM 
        Badges b
    WHERE 
        b.Class IN (1, 2, 3) 
    GROUP BY 
        b.UserId
) BadgeCount ON tu.UserId = BadgeCount.UserId
ORDER BY 
    tu.Reputation DESC,
    pd.TotalScore DESC;