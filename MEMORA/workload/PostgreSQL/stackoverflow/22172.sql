WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
RecentBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    JOIN 
        Users u ON b.UserId = u.Id
    WHERE 
        b.Date >= cast('2024-10-01' as date) - INTERVAL '6 months'
    GROUP BY 
        u.Id, b.Name
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        COUNT(ph.Id) AS CloseCount,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rb.UserId,
    rb.BadgeName,
    rb.BadgeCount,
    cp.CloseCount,
    cp.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentBadges rb ON rb.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    ClosedPosts cp ON cp.ClosedPostId = rp.PostId
WHERE 
    rp.Rank <= 3 
    OR (cp.CloseCount IS NOT NULL AND cp.CloseCount >= 1)
ORDER BY 
    rp.ViewCount DESC, rb.BadgeCount DESC
LIMIT 100;