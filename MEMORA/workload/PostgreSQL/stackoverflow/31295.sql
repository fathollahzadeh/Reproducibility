
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
), PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
), RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        DENSE_RANK() OVER (ORDER BY ph.CreationDate DESC) AS ActivityRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    (SELECT STRING_AGG(tag.TagName, ', ') 
        FROM PopularTags tag 
        JOIN Posts post ON post.Tags LIKE '%' || tag.TagName || '%'
        WHERE post.Id = rp.PostId) AS PopularTags,
    (SELECT r.ActivityRank
        FROM RecentActivity r
        WHERE r.PostId = rp.PostId) AS RecentActivityRank
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC;
