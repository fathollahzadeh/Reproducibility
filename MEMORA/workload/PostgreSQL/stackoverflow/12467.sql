
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount
    FROM 
        Posts p
)

SELECT 
    u.DisplayName,
    u.Reputation,
    upc.PostCount,
    upc.TotalScore,
    upc.QuestionsCount,
    upc.AnswersCount,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    AVG(ps.ViewCount) AS AvgViewCount,
    AVG(ps.Score) AS AvgScore,
    COUNT(ps.PostId) AS TotalPosts,
    MAX(ps.CreationDate) AS MostRecentPostDate
FROM 
    Users u
JOIN 
    UserPostCounts upc ON u.Id = upc.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, upc.PostCount, upc.TotalScore, upc.QuestionsCount, upc.AnswersCount, ub.BadgeCount
ORDER BY 
    upc.TotalScore DESC
LIMIT 100;
