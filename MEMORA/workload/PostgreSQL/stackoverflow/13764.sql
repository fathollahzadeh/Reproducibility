WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(UPT.Upvotes, 0) AS Upvotes,
        COALESCE(DWT.Downvotes, 0) AS Downvotes,
        COALESCE(CT.ClosedCount, 0) AS ClosedCount,
        COALESCE(ED.EditCount, 0) AS EditCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS Upvotes
        FROM 
            Votes
        WHERE 
            VoteTypeId = 2
        GROUP BY 
            PostId
    ) UPT ON p.Id = UPT.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS Downvotes
        FROM 
            Votes
        WHERE 
            VoteTypeId = 3
        GROUP BY 
            PostId
    ) DWT ON p.Id = DWT.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS ClosedCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId = 10
        GROUP BY 
            PostId
    ) CT ON p.Id = CT.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS EditCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId IN (4, 5, 6, 24)
        GROUP BY 
            PostId
    ) ED ON p.Id = ED.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.Upvotes,
    ps.Downvotes,
    ps.ClosedCount,
    ps.EditCount,
    (ps.Score + ps.Upvotes - ps.Downvotes) AS NetScore
FROM 
    PostStats ps
ORDER BY 
    NetScore DESC
LIMIT 100;
