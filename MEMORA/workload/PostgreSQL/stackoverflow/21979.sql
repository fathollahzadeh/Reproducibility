WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2022-01-01' 
        AND p.Score IS NOT NULL
),
CommentCounts AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
TopPostsComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(cc.TotalComments, 0) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CommentCounts cc ON rp.PostId = cc.PostId
    WHERE 
        rp.Rank <= 5 
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    CASE 
        WHEN p.CommentCount = 0 THEN 'No Comments'
        WHEN p.CommentCount BETWEEN 1 AND 5 THEN 'Few Comments'
        ELSE 'Many Comments'
    END AS CommentAvailability,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = p.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = p.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM 
    TopPostsComments p
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;