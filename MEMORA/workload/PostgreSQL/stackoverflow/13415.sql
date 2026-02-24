WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(uc.UpVoteCount, 0) AS UpVotes,
        COALESCE(dc.DownVoteCount, 0) AS DownVotes,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName
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
    ) uc ON p.Id = uc.PostId
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
    ) dc ON p.Id = dc.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
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
    ) a ON p.Id = a.ParentId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
)
SELECT 
    COUNT(*) AS TotalPosts,
    AVG(ViewCount) AS AvgViewCount,
    SUM(Score) AS TotalScore,
    SUM(UpVotes) AS TotalUpVotes,
    SUM(DownVotes) AS TotalDownVotes,
    SUM(CommentCount) AS TotalComments,
    SUM(AnswerCount) AS TotalAnswers
FROM 
    PostStats;