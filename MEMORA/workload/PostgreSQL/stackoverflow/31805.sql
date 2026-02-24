
WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        OwnerUserId AS UserId,
        MAX(CreationDate) AS RecentPostDate
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
TopUsers AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalScore,
        ups.QuestionCount,
        ups.AnswerCount,
        ra.RecentPostDate
    FROM 
        UserPostStats ups
    LEFT JOIN 
        RecentActivity ra ON ups.UserId = ra.UserId
    ORDER BY 
        ups.TotalScore DESC, ups.TotalPosts DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalScore,
    tu.QuestionCount,
    tu.AnswerCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS Badges,
    tu.RecentPostDate
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
WHERE 
    tu.AnswerCount > 10
    AND tu.RecentPostDate >= DATE '2024-10-01' - INTERVAL '1 year'
ORDER BY 
    tu.TotalScore DESC;
