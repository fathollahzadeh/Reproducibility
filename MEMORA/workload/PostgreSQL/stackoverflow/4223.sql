
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.ViewCount) AS AvgViews,
        AVG(p.Score) AS AvgScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
FilteredBadges AS (
    SELECT 
        b.UserId, 
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryActivity AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS EditsCount,
        COUNT(DISTINCT ph.PostId) AS UniquePostsEdited
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (24, 9, 10) 
    GROUP BY 
        ph.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.AvgViews,
    ups.AvgScore,
    COALESCE(fb.GoldBadges, 0) AS GoldBadges,
    COALESCE(fb.SilverBadges, 0) AS SilverBadges,
    COALESCE(fb.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(pha.EditsCount, 0) AS EditsCount,
    COALESCE(pha.UniquePostsEdited, 0) AS UniquePostsEdited,
    CAST(ups.LastPostDate AS VARCHAR) AS LastPostDate
FROM 
    UserPostStats ups
LEFT JOIN 
    FilteredBadges fb ON ups.UserId = fb.UserId
LEFT JOIN 
    PostHistoryActivity pha ON ups.UserId = pha.UserId
WHERE 
    ups.TotalPosts > 10
ORDER BY 
    ups.AvgScore DESC NULLS LAST
LIMIT 50;
