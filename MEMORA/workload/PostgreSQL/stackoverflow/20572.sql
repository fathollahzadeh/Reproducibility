
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        GREATEST(COALESCE(p.AnswerCount, 0), 0) + GREATEST(COALESCE(p.FavoriteCount, 0), 0) AS EngagementScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATE '2023-01-01'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseHistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserID,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.LastAccessDate >= DATE '2024-10-01' - INTERVAL '90 days'
    GROUP BY 
        u.Id
),
EngagedPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        CASE 
            WHEN cp.CloseHistoryCount IS NULL THEN 'Active'
            ELSE 'Closed'
        END AS PostStatus,
        au.UserID,
        au.Reputation AS UserReputation,
        rp.EngagementScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostID = cp.PostId
    LEFT JOIN 
        Posts p ON rp.PostID = p.Id
    LEFT JOIN 
        ActiveUsers au ON p.OwnerUserId = au.UserID
)
SELECT 
    ep.PostID,
    ep.Title,
    ep.Score,
    ep.ViewCount,
    ep.PostStatus,
    ep.UserReputation,
    ep.EngagementScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    EngagedPosts ep
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName
        FROM 
            Posts p
        WHERE 
            p.Id = ep.PostID
    ) t ON true
WHERE 
    ep.EngagementScore > 10
GROUP BY 
    ep.PostID, ep.Title, ep.Score, ep.ViewCount, ep.PostStatus, ep.UserReputation, ep.EngagementScore
ORDER BY 
    ep.EngagementScore DESC,
    ep.ViewCount DESC
LIMIT 50;
