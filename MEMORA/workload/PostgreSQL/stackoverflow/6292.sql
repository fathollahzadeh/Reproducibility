
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS CloseReopenCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        rp.CloseReopenCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.Score,
    t.UpVotes,
    t.DownVotes,
    t.CloseReopenCount,
    STRING_AGG(DISTINCT c.UserDisplayName, ', ') AS Commenters
FROM 
    TopPosts t
LEFT JOIN 
    Comments c ON t.PostId = c.PostId
GROUP BY 
    t.PostId, t.Title, t.CreationDate, t.Score, t.UpVotes, t.DownVotes, t.CloseReopenCount
ORDER BY 
    t.Score DESC, t.CreationDate DESC;
