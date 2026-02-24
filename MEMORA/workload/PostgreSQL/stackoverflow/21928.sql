
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        MAX(b.Class) AS HighestBadgeClass,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        ARRAY_AGG(DISTINCT t.TagName) AS PostTags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId AND b.Date <= p.CreationDate
    LEFT JOIN 
        LATERAL (
            SELECT tag.TagName FROM Tags tag 
            WHERE tag.WikiPostId = p.Id OR tag.ExcerptPostId = p.Id
        ) AS t ON TRUE
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AcceptedAnswerId, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvotesReceived,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId 
    GROUP BY 
        u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        post.OwnerUserId,
        COUNT(DISTINCT post.Id) AS TotalPosts,
        COUNT(CASE WHEN post.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days' THEN 1 END) AS RecentPosts,
        AVG(v.BountyAmount) AS AvgBountyAmount
    FROM 
        Posts post
    LEFT JOIN 
        Votes v ON post.Id = v.PostId
    GROUP BY 
        post.OwnerUserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    us.DisplayName AS OwnerDisplayName,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.UpvotesReceived,
    us.DownvotesReceived,
    ra.TotalPosts,
    ra.RecentPosts,
    ra.AvgBountyAmount,
    ARRAY_TO_STRING(ps.PostTags, ', ') AS Tags,
    CASE 
        WHEN ps.AcceptedAnswerId IS NOT NULL THEN TRUE 
        ELSE FALSE 
    END AS HasAcceptedAnswer
FROM 
    PostStats ps
JOIN 
    Users u ON ps.AcceptedAnswerId = u.Id
JOIN 
    UserStats us ON us.UserId = u.Id
JOIN 
    RecentActivity ra ON ra.OwnerUserId = u.Id
WHERE 
    us.GoldBadges > 0
    AND us.UpvotesReceived > us.DownvotesReceived
    AND (ps.Score IS NULL OR ps.Score > 5)
ORDER BY 
    ps.ViewCount DESC 
LIMIT 100;
