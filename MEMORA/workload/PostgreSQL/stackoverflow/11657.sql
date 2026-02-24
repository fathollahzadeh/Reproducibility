
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,   
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes  
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
), 
PostVoteSummary AS (
    SELECT 
        PostId, 
        SUM(UpVotes - DownVotes) AS NetVotes 
    FROM 
        PostStats
    GROUP BY 
        PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.CommentCount,
    pvs.NetVotes
FROM 
    PostStats ps
JOIN 
    PostVoteSummary pvs ON ps.PostId = pvs.PostId
ORDER BY 
    ps.CreationDate DESC;
