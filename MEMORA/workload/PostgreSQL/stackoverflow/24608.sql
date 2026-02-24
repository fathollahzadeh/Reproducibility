
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(c.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON CAST(ph.Comment AS INTEGER) = c.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate AS PostCreationDate,
    COALESCE(pb.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(pb.Badges, 'No Badges') AS UserBadges,
    cp.CloseReasons,
    CASE 
        WHEN cp.CloseReasons IS NOT NULL THEN 
            CASE 
                WHEN rp.Score >= 10 THEN 'Highly Rated & Closed'
                ELSE 'Closed Post'
            END
        ELSE 
            CASE 
                WHEN rp.Score >= 10 THEN 'Popular Content'
                ELSE 'Standard Post'
            END
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostBadges pb ON pb.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC
OFFSET 10 ROWS 
FETCH NEXT 20 ROWS ONLY;
