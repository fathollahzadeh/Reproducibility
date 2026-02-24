WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        U.DisplayName AS Author
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON rp.PostID = c.PostId
    INNER JOIN 
        Users U ON U.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostID)
    WHERE 
        rp.Rank <= 5
),
PostEngagement AS (
    SELECT 
        tp.PostID,
        tp.Title,
        tp.ViewCount,
        tp.Score,
        tp.TotalComments,
        tp.Author,
        (tp.ViewCount + tp.TotalComments) AS EngagementScore
    FROM 
        TopPosts tp
)
SELECT 
    pe.PostID,
    pe.Title,
    pe.ViewCount,
    pe.Score,
    pe.TotalComments,
    pe.Author,
    pe.EngagementScore,
    CASE 
        WHEN pe.EngagementScore > 100 THEN 'High Engagement'
        WHEN pe.EngagementScore BETWEEN 50 AND 100 THEN 'Moderate Engagement'
        ELSE 'Low Engagement' 
    END AS EngagementLevel
FROM 
    PostEngagement pe
WHERE 
    pe.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
ORDER BY 
    pe.EngagementScore DESC;