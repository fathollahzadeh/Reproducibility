
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(ans.AnswerCount, 0) AS AnswerCount,
        COALESCE(com.CommentCount, 0) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) ans ON p.Id = ans.ParentId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) com ON p.Id = com.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        ans.AnswerCount, 
        com.CommentCount
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.Score,
        ps.AnswerCount,
        ps.CommentCount,
        RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS PostRank
    FROM 
        PostStats ps
)
SELECT 
    r.PostId,
    r.Title,
    r.ViewCount,
    r.Score,
    r.AnswerCount,
    r.CommentCount,
    CASE 
        WHEN r.PostRank <= 5 THEN 'Top 5'
        WHEN r.PostRank BETWEEN 6 AND 20 THEN 'Popular'
        ELSE 'Other'
    END AS PostCategory
FROM 
    RankedPosts r
WHERE 
    r.AnswerCount > 0 
    AND r.ViewCount IS NOT NULL
ORDER BY 
    r.PostRank;
