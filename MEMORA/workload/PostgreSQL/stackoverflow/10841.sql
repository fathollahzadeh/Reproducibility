
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        EXTRACT(EPOCH FROM (COALESCE(p.ClosedDate, p.LastActivityDate) - p.CreationDate)) AS PostAgeInSeconds,
        p.CreationDate,
        p.LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate
),
AverageMetrics AS (
    SELECT 
        AVG(PostAgeInSeconds) AS AveragePostAge,
        AVG(CommentCount) AS AverageCommentCount,
        AVG(UpVotes) AS AverageUpVotes,
        AVG(DownVotes) AS AverageDownVotes
    FROM 
        PostMetrics
)

SELECT 
    pm.Title,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.PostAgeInSeconds,
    am.AveragePostAge,
    am.AverageCommentCount,
    am.AverageUpVotes,
    am.AverageDownVotes
FROM 
    PostMetrics pm
CROSS JOIN 
    AverageMetrics am
ORDER BY 
    pm.PostAgeInSeconds DESC;
