
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.ViewCount,
        COALESCE(pa.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank,
        STRING_AGG(t.TagName, ',') AS FormattedTags
    FROM 
        Posts p
    LEFT JOIN 
        Posts pa ON p.AcceptedAnswerId = pa.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%' 
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Tags, p.Score, p.ViewCount, pa.AcceptedAnswerId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.FormattedTags,
        rp.Score,
        rp.ViewCount,
        rp.AcceptedAnswerId,
        rp.CommentCount,
        CASE 
            WHEN rp.Score > 10 AND rp.ViewCount > 1000 THEN 'High Engagement'
            WHEN rp.Score BETWEEN 5 AND 10 AND rp.ViewCount BETWEEN 500 AND 1000 THEN 'Medium Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.FormattedTags,
    fp.Score,
    fp.ViewCount,
    fp.AcceptedAnswerId,
    fp.CommentCount,
    fp.EngagementLevel,
    (SELECT COUNT(DISTINCT b.Id) 
     FROM Badges b 
     WHERE b.UserId = (SELECT OwnerUserId FROM Posts p WHERE p.Id = fp.PostId)) AS UserBadgeCount
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC;
