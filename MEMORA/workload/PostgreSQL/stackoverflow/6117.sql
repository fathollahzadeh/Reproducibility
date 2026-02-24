WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
),
UserBadges AS (
    SELECT 
        b.UserId,
        b.Class,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId, b.Class
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ph.EditCount, 0) AS TotalEdits,
    COALESCE(ph.CloseOpenCount, 0) AS CloseOpenStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.PostId = ub.UserId
LEFT JOIN 
    PostHistoryAggregates ph ON rp.PostId = ph.PostId
WHERE 
    rp.UserPostRank <= 5
ORDER BY 
    rp.CreationDate DESC, TotalBadges DESC;
