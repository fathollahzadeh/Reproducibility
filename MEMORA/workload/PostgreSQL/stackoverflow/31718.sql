
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName
), 
RecentActivities AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS ActivityDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LatestActivity
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '3 MONTH'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    CASE 
        WHEN ra.ActivityDate IS NOT NULL THEN 'Recently Active'
        ELSE 'Inactive'
    END AS ActivityStatus,
    rp.VoteCount,
    EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - rp.CreationDate)) AS DaysSinceCreated
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivities ra ON rp.PostId = ra.PostId
WHERE 
    rp.PostRank <= 10 
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
