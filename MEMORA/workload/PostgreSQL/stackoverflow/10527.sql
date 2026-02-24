WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        p.CreationDate,
        p.ViewCount,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.Reputation
),
AverageStats AS (
    SELECT 
        AVG(CommentCount) AS AvgComments,
        AVG(VoteCount) AS AvgVotes,
        AVG(UpVotes) AS AvgUpVotes,
        AVG(DownVotes) AS AvgDownVotes,
        AVG(ViewCount) AS AvgViewCount,
        AVG(OwnerReputation) AS AvgOwnerReputation
    FROM 
        PostStats
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.ViewCount,
    ps.OwnerReputation,
    a.AvgComments,
    a.AvgVotes,
    a.AvgUpVotes,
    a.AvgDownVotes,
    a.AvgViewCount,
    a.AvgOwnerReputation
FROM 
    PostStats ps, AverageStats a
ORDER BY 
    ps.ViewCount DESC
LIMIT 100;