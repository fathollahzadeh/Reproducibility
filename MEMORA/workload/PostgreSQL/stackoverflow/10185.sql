
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgActiveDurationInSeconds
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId
)

SELECT 
    pt.Name AS PostType,
    COUNT(ps.PostId) AS TotalPosts,
    SUM(ps.CommentCount) AS TotalComments,
    SUM(ps.VoteCount) AS TotalVotes,
    SUM(ps.UpVoteCount) AS TotalUpVotes,
    SUM(ps.DownVoteCount) AS TotalDownVotes,
    AVG(ps.AvgActiveDurationInSeconds) AS AvgActiveDuration
FROM 
    PostStats ps
JOIN 
    PostTypes pt ON ps.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
