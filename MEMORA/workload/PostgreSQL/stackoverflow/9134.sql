
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = trp.PostId AND ph.PostHistoryTypeId = 10) AS CloseCount,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = trp.PostId AND ph.PostHistoryTypeId = 11) AS ReopenCount
FROM 
    TopRankedPosts trp
LEFT JOIN 
    Votes v ON trp.PostId = v.PostId
GROUP BY 
    trp.PostId, trp.Title, trp.CreationDate, trp.Score, trp.ViewCount
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC;
