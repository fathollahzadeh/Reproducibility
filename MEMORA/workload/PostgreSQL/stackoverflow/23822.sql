
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        p.Tags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(*) > 10
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(b.Id) > 0
), 
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.UserId,
        ph.CreationDate AS HistoryDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS ActivityRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    COALESCE(pt.TagCount, 0) AS PopularTagCount,
    ub.BadgeCount,
    pa.CloseReason
FROM 
    RankedPosts r
LEFT JOIN 
    PopularTags pt ON r.Tags LIKE CONCAT('%', pt.TagName, '%')
LEFT JOIN 
    UserBadges ub ON r.PostId = ub.UserId
LEFT JOIN 
    PostActivity pa ON r.PostId = pa.PostId AND pa.ActivityRank = 1
WHERE 
    r.PostRank = 1 AND 
    (COALESCE(pa.CloseReason, '') <> '' OR COALESCE(ub.BadgeCount, 0) >= 2) 
ORDER BY 
    r.CreationDate DESC
LIMIT 10;
