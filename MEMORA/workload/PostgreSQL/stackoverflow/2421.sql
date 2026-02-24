
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        ps.TotalPosts,
        ps.QuestionCount,
        ps.AnswerCount,
        COALESCE(ps.AvgScore, 0) AS AvgScore
    FROM 
        UserBadges ub
    LEFT JOIN 
        PostStatistics ps ON ub.UserId = ps.OwnerUserId
    WHERE 
        ub.BadgeCount > 0
)
SELECT 
    u.DisplayName,
    u.Reputation,
    t.BadgeCount,
    t.TotalPosts,
    t.QuestionCount,
    t.AnswerCount,
    t.AvgScore,
    CASE 
        WHEN t.TotalPosts IS NULL THEN 'No Posts'
        WHEN t.TotalPosts > 100 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributionLevel
FROM 
    Users u
LEFT JOIN 
    TopUsers t ON u.Id = t.UserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    t.BadgeCount DESC, 
    u.Reputation DESC
FETCH FIRST 10 ROWS ONLY;
