
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        u.Reputation AS OwnerReputation,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT bh.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
            Votes
         GROUP BY 
            PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory bh ON p.Id = bh.PostId
    WHERE 
        p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
        u.DisplayName, u.Reputation, v.UpVotes, v.DownVotes
),
Ranking AS (
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS Rank
    FROM 
        PostDetails pd
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.OwnerName,
    r.OwnerReputation,
    r.UpVotes,
    r.DownVotes,
    r.CommentCount,
    r.HistoryCount,
    r.Rank
FROM 
    Ranking r
WHERE 
    r.Rank <= 100
ORDER BY 
    r.Rank;
