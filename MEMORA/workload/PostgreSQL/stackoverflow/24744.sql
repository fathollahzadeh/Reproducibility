
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
),
PostActivity AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(DISTINCT ph.UserId) AS EditorCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END) AS CloseReason
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS INTEGER)
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerReputation,
    CASE 
        WHEN pac.PostId IS NOT NULL THEN 'Post has been edited'
        ELSE 'No edits'
    END AS EditStatus,
    pcr.CloseReason,
    ub.BadgeNames
FROM 
    RankedPosts rp
LEFT JOIN 
    PostActivity pac ON rp.Id = pac.PostId
LEFT JOIN 
    PostCloseReasons pcr ON rp.Id = pcr.PostId
LEFT JOIN 
    UserBadges ub ON rp.Id = (SELECT COALESCE(MAX(OwnerUserId), -1) FROM Posts WHERE Id = rp.Id) 
WHERE 
    rp.RankByScore <= 10 AND 
    rp.RankByDate <= 30
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
