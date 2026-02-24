
WITH LatestUserBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        b.Class,
        ROW_NUMBER() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM Badges b
    WHERE b.Class = 1  
),
ActiveUserPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - p.CreationDate)) / 3600 AS AgeInHours,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId, p.CreationDate
),
UserPostMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT ap.PostId) AS TotalPosts,
        COALESCE(SUM(CASE WHEN ap.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN ap.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        AVG(ap.AgeInHours) AS AvgPostAge,
        MAX(ap.CommentCount) AS MaxCommentsPerPost
    FROM Users u
    LEFT JOIN ActiveUserPosts ap ON u.Id = ap.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostsRanked AS (
    SELECT 
        upm.UserId,
        upm.DisplayName,
        upm.TotalPosts,
        upm.TotalQuestions,
        upm.TotalAnswers,
        upm.AvgPostAge,
        upm.MaxCommentsPerPost,
        lb.BadgeName,
        ROW_NUMBER() OVER (ORDER BY upm.TotalPosts DESC, upm.MaxCommentsPerPost DESC) AS UserRank
    FROM UserPostMetrics upm
    LEFT JOIN LatestUserBadges lb ON upm.UserId = lb.UserId AND lb.BadgeRank = 1
)
SELECT 
    pr.UserId,
    pr.DisplayName,
    pr.TotalPosts, 
    pr.TotalQuestions,
    pr.TotalAnswers,
    pr.AvgPostAge,
    pr.MaxCommentsPerPost,
    COALESCE(pr.BadgeName, 'No Gold Badge') AS TopBadge,
    CASE 
        WHEN pr.AvgPostAge < 24 THEN 'New Posters'
        WHEN pr.AvgPostAge BETWEEN 24 AND 720 THEN 'Regular Posters'
        ELSE 'Old Posters'
    END AS PosterCategory
FROM PostsRanked pr
WHERE pr.UserRank <= 10
ORDER BY pr.TotalPosts DESC, pr.MaxCommentsPerPost DESC;
