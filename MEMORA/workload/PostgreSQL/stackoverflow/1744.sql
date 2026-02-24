WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
PopularTags AS (
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
        COUNT(p.Id) > 5 
),
RecentPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score, 
        rp.OwnerDisplayName, 
        COALESCE(bp.BestResponse, 'No accepted answer') AS BestResponse
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            p.AcceptedAnswerId,
            p.Title AS BestResponse
        FROM 
            Posts p 
        WHERE 
            p.AcceptedAnswerId IS NOT NULL
    ) bp ON rp.PostId = bp.AcceptedAnswerId
    WHERE 
        rp.Rank = 1
)
SELECT 
    rp.Title, 
    rp.CreationDate, 
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    pt.TagName,
    CASE 
        WHEN rp.Score > (SELECT AVG(Score) FROM Posts) THEN 'Above Average'
        ELSE 'Below Average'
    END AS ScoreComparison,
    COUNT(c.Id) AS CommentCount 
FROM 
    RecentPosts rp
LEFT JOIN 
    PopularTags pt ON rp.Title LIKE '%' || pt.TagName || '%'
LEFT JOIN 
    Comments c ON c.PostId = rp.PostId
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.OwnerDisplayName, pt.TagName
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 10;