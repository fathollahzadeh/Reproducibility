
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT b.Name) AS BadgeNames,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.BadgeNames,
        CASE 
            WHEN rp.PostRank = 1 THEN 'Latest Post'
            ELSE 'Older Post'
        END AS PostStatus
    FROM 
        RankedPosts rp
),
FilteredAnalytics AS (
    SELECT 
        pa.*,
        ARRAY_LENGTH(string_to_array(pa.Tags, '>'), 1) AS TagCount
    FROM 
        PostAnalytics pa
    WHERE 
        pa.Score > 0 AND 
        pa.ViewCount > 50
)

SELECT 
    fa.PostId,
    fa.Title,
    fa.OwnerDisplayName,
    fa.CreationDate,
    fa.Score,
    fa.ViewCount,
    fa.CommentCount,
    fa.TagCount,
    fa.BadgeNames,
    fa.PostStatus,
    EXTRACT(EPOCH FROM (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - fa.CreationDate)) AS TimeSincePostCreation
FROM 
    FilteredAnalytics fa
ORDER BY 
    fa.Score DESC, fa.ViewCount DESC
LIMIT 100;
