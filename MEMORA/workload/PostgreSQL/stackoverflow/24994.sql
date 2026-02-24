WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND 
        p.Score > 0
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.CreationDate,
        NULLIF(STRING_AGG(DISTINCT b.Name, ', ') FILTER (WHERE b.Class = 1), '') AS GoldBadges,
        NULLIF(STRING_AGG(DISTINCT b.Name, ', ') FILTER (WHERE b.Class = 2), '') AS SilverBadges,
        NULLIF(STRING_AGG(DISTINCT b.Name, ', ') FILTER (WHERE b.Class = 3), '') AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName, u.CreationDate
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        ru.DisplayName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        CASE 
            WHEN rp.TotalPosts > 0 THEN (CAST(rp.rn AS float) / rp.TotalPosts) * 100
            ELSE 0
        END AS PostRankPercentage
    FROM 
        RankedPosts rp
    JOIN 
        RecentUsers ru ON rp.OwnerUserId = ru.UserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON rp.PostId = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON rp.PostId = v.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.DisplayName,
    ps.CreationDate,
    ps.CommentCount,
    ps.VoteCount,
    ps.PostRankPercentage,
    CASE 
        WHEN ps.PostRankPercentage > 75 THEN 'High Engagement'
        WHEN ps.PostRankPercentage > 50 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    COALESCE(bd.GoldBadges, 'None') AS GoldBadges,
    COALESCE(bd.SilverBadges, 'None') AS SilverBadges,
    COALESCE(bd.BronzeBadges, 'None') AS BronzeBadges
FROM 
    PostStats ps
LEFT JOIN 
    RecentUsers bd ON ps.OwnerUserId = bd.UserId
WHERE 
    ps.VoteCount > 10 
    OR ps.CommentCount > 5 
ORDER BY 
    ps.PostRankPercentage DESC,
    ps.CreationDate DESC
LIMIT 50;