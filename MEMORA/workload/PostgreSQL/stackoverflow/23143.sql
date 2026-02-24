WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE 
                WHEN v.VoteTypeId IN (2, 3) THEN 1 
                ELSE 0 END) AS VoteCount,
        COUNT(b.Id) AS BadgeCount,
        AVG(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - u.CreationDate)) / 3600) AS AvgAccountAgeHours
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RN
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    ua.TotalBounty,
    ua.VoteCount,
    ua.BadgeCount,
    ua.AvgAccountAgeHours,
    cp.CloseReason AS LastCloseReason
FROM 
    RankedPosts rp
LEFT JOIN 
    UserActivity ua ON ua.UserId = rp.PostId 
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId AND cp.RN = 1 
WHERE 
    rp.RN <= 5 
ORDER BY 
    rp.ViewCount DESC
LIMIT 50;