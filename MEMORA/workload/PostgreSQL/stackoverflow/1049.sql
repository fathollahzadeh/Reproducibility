
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS AuthorDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01' AND p.Score > 0
),
HistoricalVotes AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS VoteCount,
        MIN(ph.CreationDate) AS FirstVoteDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AuthorDisplayName,
        rp.CommentCount,
        hv.VoteCount AS HistoricalVoteCount,
        hv.FirstVoteDate 
    FROM 
        RankedPosts rp
    LEFT JOIN 
        HistoricalVotes hv ON rp.Id = hv.PostId
    WHERE 
        rp.PostRank <= 10 
)
SELECT 
    tp.Id,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AuthorDisplayName,
    COALESCE(tp.CommentCount, 0) AS TotalComments,
    COALESCE(tp.HistoricalVoteCount, 0) AS HistoricalVoteCount,
    COALESCE(EXTRACT(EPOCH FROM tp.FirstVoteDate), 0) AS FirstVoteTimeInSeconds
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
