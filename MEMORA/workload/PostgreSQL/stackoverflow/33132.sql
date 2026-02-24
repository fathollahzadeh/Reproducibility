WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        ub.BadgeCount,
        ub.HighestBadgeClass,
        phs.CloseCount,
        phs.DeleteCount
    FROM 
        RankedPosts rp
    JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        PostHistorySummary phs ON rp.PostId = phs.PostId
    WHERE 
        rp.UserRank <= 5 
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.BadgeCount,
    tp.HighestBadgeClass,
    COALESCE(tp.CloseCount, 0) AS CloseCount,
    COALESCE(tp.DeleteCount, 0) AS DeleteCount,
    CASE 
        WHEN tp.HighestBadgeClass = 1 THEN 'Gold'
        WHEN tp.HighestBadgeClass = 2 THEN 'Silver'
        WHEN tp.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS BadgeType,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount
FROM 
    TopPosts tp
ORDER BY 
    tp.CreationDate DESC
FETCH FIRST 50 ROWS ONLY;