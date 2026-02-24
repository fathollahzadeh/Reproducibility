WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        COALESCE(UP.AnswerCount, 0) AS AnswerCount,
        COALESCE(CS.CommentCount, 0) AS CommentCount,
        COALESCE(V.TotalVotes, 0) AS TotalVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
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
    ) AS UP ON p.Id = UP.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) AS CS ON p.Id = CS.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) AS V ON p.Id = V.PostId
    WHERE 
        p.PostTypeId = 1  
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Body,
        rp.AnswerCount,
        rp.CommentCount,
        rp.TotalVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1  
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    LENGTH(fp.Body) - LENGTH(REPLACE(fp.Body, ' ', '')) + 1 AS WordCount,  
    fp.AnswerCount,
    fp.CommentCount,
    fp.TotalVotes
FROM 
    FilteredPosts fp
WHERE 
    fp.AnswerCount > 0 OR fp.CommentCount > 0  
ORDER BY 
    fp.TotalVotes DESC,  
    fp.CreationDate DESC;