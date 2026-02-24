
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.CreationDate, p.Score, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
Benchmark AS (
    SELECT 
        ps.PostId,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        ps.AnswerCount,
        ps.LastVoteDate,
        us.UserId,
        us.BadgeCount,
        us.TotalUpVotes,
        us.TotalDownVotes
    FROM 
        PostStats ps
    JOIN 
        Users u ON ps.PostId = u.AccountId  
    JOIN 
        UserStats us ON u.Id = us.UserId
)
SELECT 
    *,
    (ViewCount / NULLIF(AnswerCount, 0)) AS ViewToAnswerRatio,
    (TotalUpVotes - TotalDownVotes) AS NetVotes
FROM 
    Benchmark
ORDER BY 
    ViewCount DESC
LIMIT 100;
