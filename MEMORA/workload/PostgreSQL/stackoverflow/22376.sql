WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.ViewCount IS NULL THEN 0 ELSE p.ViewCount END) AS TotalViews,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountySpent
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Owner,
        rp.Score,
        ua.BadgeCount,
        ua.TotalViews,
        ua.TotalBountySpent
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserActivity ua ON ua.UserId = (
            SELECT u.Id 
            FROM Users u 
            WHERE u.DisplayName = rp.Owner
            LIMIT 1)
    WHERE 
        rp.rn <= 10 
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Owner,
    fp.Score,
    COALESCE(fp.BadgeCount, 0) AS BadgeCount,
    COALESCE(fp.TotalViews, 0) AS TotalViews,
    COALESCE(fp.TotalBountySpent, 0) AS TotalBountySpent,
    CASE
        WHEN fp.Score IS NULL THEN 'No Answers' 
        WHEN fp.Score > 10 THEN 'Popular' 
        WHEN fp.Score BETWEEN 1 AND 10 THEN 'Moderate'
        ELSE 'Unpopular'
    END AS PopularityCategory
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistory ph ON fp.PostId = ph.PostId AND ph.PostHistoryTypeId = 4 
WHERE 
    ph.CreationDate IS NULL OR ph.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 month' 
ORDER BY 
    fp.Score DESC, 
    fp.CreationDate ASC
LIMIT 50;