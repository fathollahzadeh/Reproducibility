WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END), 0) AS AcceptedVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate
)
SELECT 
    pt.Name AS PostType,
    COUNT(pm.PostId) AS TotalPosts,
    AVG(pm.CommentCount) AS AvgCommentsPerPost,
    AVG(pm.VoteCount) AS AvgVotesPerPost,
    AVG(pm.UpVoteCount) AS AvgUpVotesPerPost,
    AVG(pm.DownVoteCount) AS AvgDownVotesPerPost,
    AVG(pm.AcceptedVoteCount) AS AvgAcceptedVotesPerPost
FROM 
    PostTypes pt
LEFT JOIN 
    PostMetrics pm ON pt.Id = pm.PostTypeId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;