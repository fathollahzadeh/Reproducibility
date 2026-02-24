
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(v.VoteTypeId), 0) AS MaxVoteType,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, p.PostTypeId
),
TopRankedPosts AS (
    SELECT * FROM RankedPosts WHERE ScoreRank <= 10
),
PostHistoryAggregated AS (
    SELECT 
        h.PostId,
        COUNT(h.Id) AS EditCount,
        COUNT(CASE WHEN h.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN h.PostHistoryTypeId = 19 THEN 1 END) AS ProtectCount
    FROM 
        PostHistory h
    GROUP BY 
        h.PostId
)
SELECT 
    tr.PostId,
    tr.Title,
    tr.CreationDate,
    tr.ViewCount,
    tr.Score,
    tr.Author,
    tr.CommentCount,
    tr.MaxVoteType,
    pha.EditCount,
    pha.CloseCount,
    pha.ProtectCount
FROM 
    TopRankedPosts tr
LEFT JOIN 
    PostHistoryAggregated pha ON tr.PostId = pha.PostId
ORDER BY 
    tr.Score DESC, tr.ViewCount DESC;
