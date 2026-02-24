
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5 
),
PostHistorySummary AS (
    SELECT
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        p.Id
)
SELECT
    p.Id,
    p.Title,
    u.DisplayName AS Owner,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(b.MaxBadgeClass, 0) AS MaxBadgeClass,
    phs.EditCount,
    phs.LastEdited,
    tp.TagName,
    tp.TagCount,
    rp.ViewCount,
    rp.Score
FROM
    Posts p
JOIN
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN
    UserWithBadges b ON b.UserId = u.Id
LEFT JOIN
    PostHistorySummary phs ON phs.PostId = p.Id
LEFT JOIN 
    PopularTags tp ON tp.TagName = ANY(string_to_array(p.Tags, ','))
LEFT JOIN 
    RankedPosts rp ON rp.PostId = p.Id
WHERE
    p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
    AND (p.Score > 0 OR p.ViewCount > 100)
ORDER BY
    rp.Rank, b.MaxBadgeClass DESC, phs.LastEdited DESC;
