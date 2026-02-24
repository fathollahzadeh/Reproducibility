WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts AS p
    LEFT JOIN 
        Votes AS v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        p.Title AS ClosedPostTitle,
        ph.Comment AS ClosureReason
    FROM 
        PostHistory AS ph
    JOIN 
        Posts AS p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10  
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges AS b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE WHEN cp.ClosureReason IS NOT NULL THEN 'Closed' ELSE 'Active' END AS PostStatus,
    cb.BadgeCount AS UserGoldBadgeCount
FROM 
    RankedPosts AS rp
LEFT JOIN 
    ClosedPosts AS cp ON rp.Id = cp.PostId
LEFT JOIN 
    Users AS u ON rp.Id = u.Id
LEFT JOIN 
    UserBadges AS cb ON u.Id = cb.UserId
WHERE 
    (rp.UpVotes - rp.DownVotes) > 0 
    AND (rp.Score > 10 OR rp.ViewCount > 100) 
ORDER BY 
    rp.Rank
FETCH FIRST 50 ROWS ONLY;