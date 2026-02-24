WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(UPV.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(DNV.DownVoteCount, 0) AS DownVoteCount,
        COALESCE(MV.ModeratorReviewCount, 0) AS ModeratorReviewCount,
        COALESCE(CR.CloseReasonCount, 0) AS CloseReasonCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS UpVoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            PostId
    ) UPV ON p.Id = UPV.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS DownVoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 3 
        GROUP BY 
            PostId
    ) DNV ON p.Id = DNV.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS ModeratorReviewCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 15 
        GROUP BY 
            PostId
    ) MV ON p.Id = MV.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CloseReasonCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId = 10 
        GROUP BY 
            PostId
    ) CR ON p.Id = CR.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.ModeratorReviewCount,
    ps.CloseReasonCount
FROM 
    PostStatistics ps
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
LIMIT 100;