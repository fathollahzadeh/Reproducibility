
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score
),
MaxScores AS (
    SELECT 
        OwnerUserId,
        MAX(Score) AS MaxScore
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
PostHistoryAggregation AS (
    SELECT 
        ph.PostId,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 1 ELSE 0 END) AS CloseActionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    rp.Score,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    CASE 
        WHEN mp.MaxScore IS NOT NULL THEN 
            CASE 
                WHEN rp.Score = mp.MaxScore THEN 'Top Performer'
                ELSE 'Regular Performer'
            END 
        ELSE 'No Posts'
    END AS PerformanceLabel,
    COALESCE(pa.CloseActionCount, 0) AS CloseActionCount
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    MaxScores mp ON rp.OwnerUserId = mp.OwnerUserId
LEFT JOIN 
    PostHistoryAggregation pa ON rp.PostId = pa.PostId
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
