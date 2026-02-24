WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (4,5) THEN 1 ELSE 0 END) AS TotalWikis,
        AVG(p.Score) AS AverageScore,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
UserSummary AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.TotalWikis,
        ups.AverageScore,
        bu.BadgeCount,
        bu.HighestBadgeClass
    FROM 
        UserPostStats ups
    LEFT JOIN 
        BadgedUsers bu ON ups.UserId = bu.UserId
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalWikis,
    COALESCE(us.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN us.BadgeCount > 0 THEN 
            CASE 
                WHEN us.HighestBadgeClass = 1 THEN 'Gold'
                WHEN us.HighestBadgeClass = 2 THEN 'Silver'
                ELSE 'Bronze'
            END
        ELSE 'None'
    END AS HighestBadge,
    us.AverageScore,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = us.UserId AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year') AS PostsLastYear
FROM 
    UserSummary us
WHERE 
    us.TotalPosts > 10
ORDER BY 
    us.TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;