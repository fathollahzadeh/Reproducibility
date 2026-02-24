
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, u.DisplayName
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.BadgeCount,
        CASE 
            WHEN rp.ViewCount > 100 THEN 'High Traffic'
            WHEN rp.ViewCount > 50 THEN 'Medium Traffic'
            ELSE 'Low Traffic'
        END AS TrafficCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5 
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.CreationDate,
    fp.ViewCount,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.BadgeCount,
    fp.TrafficCategory,
    STRING_AGG(t.TagName, ', ') AS AssociatedTags
FROM 
    FilteredPosts fp
LEFT JOIN 
    Tags t ON t.Count > 3 AND POSITION(fp.Tags IN t.TagName) > 0 
GROUP BY 
    fp.PostId, fp.Title, fp.Body, fp.Tags, fp.CreationDate, fp.ViewCount, fp.OwnerDisplayName, fp.CommentCount, fp.BadgeCount, fp.TrafficCategory
ORDER BY 
    fp.ViewCount DESC, fp.TrafficCategory DESC;
