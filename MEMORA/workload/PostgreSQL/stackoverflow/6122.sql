
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.Score,
        rp.CreationDate,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(pa.AnswerCount, 0) AS AnswerCount,
        COALESCE(pv.UpVotes, 0) AS TotalUpVotes,
        COALESCE(pv.DownVotes, 0) AS TotalDownVotes,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) pc ON rp.PostId = pc.PostId
    LEFT JOIN (
        SELECT 
            ParentId AS PostId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) pa ON rp.PostId = pa.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) pv ON rp.PostId = pv.PostId
)
SELECT 
    pd.OwnerName,
    COUNT(pd.PostId) AS TotalQuestions,
    AVG(pd.Score) AS AverageScore,
    SUM(pd.AnswerCount) AS TotalAnswers,
    SUM(pd.CommentCount) AS TotalComments,
    SUM(pd.TotalUpVotes) AS TotalUpVotes,
    SUM(pd.TotalDownVotes) AS TotalDownVotes
FROM 
    PostDetails pd
WHERE 
    pd.Rank <= 5 
GROUP BY 
    pd.OwnerName, pd.Rank
ORDER BY 
    TotalQuestions DESC, 
    AverageScore DESC;
