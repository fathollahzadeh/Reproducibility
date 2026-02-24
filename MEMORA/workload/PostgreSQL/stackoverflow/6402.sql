WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.AcceptedAnswerId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, a.AcceptedAnswerId
),
TopPostStats AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        PostStats
)
SELECT 
    t.Title,
    t.Score,
    t.ViewCount,
    t.AcceptedAnswerId,
    t.CommentCount,
    t.UpVotes,
    t.DownVotes,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    t.Rank
FROM 
    TopPostStats t
JOIN 
    Users u ON t.PostId = u.Id
WHERE 
    t.Rank <= 10
ORDER BY 
    t.Rank;