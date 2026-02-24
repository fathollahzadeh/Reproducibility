WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        SUM(p.Score) OVER (PARTITION BY p.OwnerUserId) AS TotalOwnerScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), 

PostHistories AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.Text,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)  
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

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.TotalOwnerScore,
        ub.BadgeCount,
        ub.HighestBadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.OwnerPostRank = 1
        AND rp.Score > 0
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    COALESCE(fp.Score, 0) AS PostScore,
    COALESCE(fp.TotalOwnerScore, 0) AS OwnerTotalScore,
    COALESCE(fp.BadgeCount, 0) AS UserBadgeCount,
    CASE WHEN fp.HighestBadgeClass IS NOT NULL THEN
        CASE 
            WHEN fp.HighestBadgeClass = 1 THEN 'Gold'
            WHEN fp.HighestBadgeClass = 2 THEN 'Silver'
            WHEN fp.HighestBadgeClass = 3 THEN 'Bronze'
            ELSE 'No Badge'
        END
    ELSE 'No Badge' END AS UserHighestBadge,
    (SELECT 
        COUNT(DISTINCT phh.UserId) 
     FROM 
        PostHistories phh 
     WHERE 
        phh.PostId = fp.PostId AND phh.HistoryRank = 1) AS LatestEditorCount
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.PostId DESC;