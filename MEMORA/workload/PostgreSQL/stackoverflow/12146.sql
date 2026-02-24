
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.AnswerCount) AS AvgAnswerCount,
        AVG(p.CommentCount) AS AvgCommentCount
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    p.PostTypeId,
    p.TotalPosts,
    p.PositiveScorePosts,
    p.NegativeScorePosts,
    p.AvgViewCount,
    p.AvgAnswerCount,
    p.AvgCommentCount,
    u.UserId,
    u.PostCount,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges
FROM 
    PostStats p
LEFT JOIN 
    UserStats u ON u.PostCount > 0
ORDER BY 
    p.PostTypeId, u.PostCount DESC;
