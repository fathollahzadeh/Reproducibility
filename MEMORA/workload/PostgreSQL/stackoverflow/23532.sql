WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as rn,
        COUNT(c.Id) OVER(PARTITION BY p.Id) as CommentCount,
        STRING_AGG(t.TagName, ', ') FILTER (WHERE t.TagName IS NOT NULL) OVER(PARTITION BY p.Id) as Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(p.Tags, ',')) as TagName) t ON TRUE
    WHERE 
        p.Score IS NOT NULL
), UserActivity AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) as PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) as TotalBounty,
        MAX(p.CreationDate) as LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    WHERE 
        u.Reputation > 50
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), RecentClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.UserId,
        RANK() OVER(ORDER BY ph.CreationDate DESC) as RecentCloseRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10  
    WHERE 
        ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.Tags,
    rcp.Title AS RecentlyClosedPost,
    rcp.RecentCloseRank,
    u.TotalBounty
FROM 
    UserActivity u
JOIN 
    RankedPosts rp ON u.PostCount > 5
LEFT JOIN 
    RecentClosedPosts rcp ON rcp.UserId = u.UserId
WHERE 
    COALESCE(u.TotalBounty, 0) > 0
ORDER BY 
    u.Reputation DESC, 
    rp.Score DESC NULLS LAST, 
    rcp.RecentCloseRank ASC NULLS FIRST
LIMIT 50;