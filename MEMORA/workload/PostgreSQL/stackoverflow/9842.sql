
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(EXTRACT(EPOCH FROM (COALESCE(NULLIF(p.LastActivityDate, '1970-01-01'), '2024-10-01 12:34:56') - p.CreationDate))) AS AverageActiveDuration
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '1 year') 
        AND p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.PostTypeId,
        ps.CommentCount,
        ps.VoteCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.AverageActiveDuration,
        RANK() OVER (PARTITION BY ps.PostTypeId ORDER BY ps.VoteCount DESC, ps.CommentCount DESC) AS Rank
    FROM 
        PostStats ps
)
SELECT 
    t.Title,
    CASE 
        WHEN t.PostTypeId = 1 THEN 'Question'
        WHEN t.PostTypeId = 2 THEN 'Answer'
    END AS PostType,
    t.CommentCount,
    t.VoteCount,
    t.UpVotes,
    t.DownVotes,
    t.AverageActiveDuration
FROM 
    TopPosts t
WHERE 
    t.Rank <= 10  
ORDER BY 
    t.PostTypeId, t.Rank;
