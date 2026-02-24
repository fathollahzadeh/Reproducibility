
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(b.Name, 'None') AS BadgeName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.Reputation, b.Name
),
PostRanking AS (
    SELECT 
        PostId,
        Title,
        Score + UpVotes - DownVotes AS NetScore,
        CreationDate,
        CommentCount,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Score + UpVotes - DownVotes DESC) AS Rank
    FROM 
        PostStats
)
SELECT 
    PostId,
    Title,
    CreationDate,
    NetScore,
    CommentCount,
    Reputation,
    Rank
FROM 
    PostRanking
WHERE 
    Rank <= 10;
