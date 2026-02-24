WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostMetrics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(pc.PostCount, 0) AS PostCount,
        COALESCE(pc.TotalScore, 0) AS TotalScore,
        COALESCE(uc.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        PostMetrics pc ON u.Id = pc.OwnerUserId
    LEFT JOIN 
        UserBadgeCounts uc ON u.Id = uc.UserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.BadgeCount,
    CASE 
        WHEN tu.PostCount > 50 THEN 'High Contributor'
        WHEN tu.PostCount BETWEEN 20 AND 50 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM 
    TopUsers tu
ORDER BY 
    tu.TotalScore DESC, 
    tu.PostCount DESC
LIMIT 10;
