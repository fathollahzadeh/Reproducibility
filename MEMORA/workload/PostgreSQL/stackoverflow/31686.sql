
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > DATE '2024-10-01' - INTERVAL '1 year'
        AND p.PostTypeId = 1 
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        vt.Name AS VoteType,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= DATE '2024-10-01' - INTERVAL '7 days'
    GROUP BY 
        v.PostId, v.UserId, vt.Name
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
        COALESCE(phs.HistoryCount, 0) AS HistoryCount,
        COALESCE(phs.CloseCount, 0) AS CloseCount,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS OverallRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    LEFT JOIN 
        PostHistoryStats phs ON rp.PostId = phs.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.RecentVoteCount,
    tp.HistoryCount,
    tp.CloseCount,
    AVG(u.Reputation) AS AverageReputationWhenPosted
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON EXISTS (
        SELECT 1 
        FROM Posts p
        WHERE p.Id = tp.PostId AND p.OwnerUserId = u.Id
    )
WHERE 
    tp.OverallRank <= 10
    AND tp.CloseCount = 0 
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount,
    tp.RecentVoteCount, tp.HistoryCount, tp.CloseCount
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
