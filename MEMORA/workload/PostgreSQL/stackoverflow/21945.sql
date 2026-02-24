WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - interval '1 year'
    GROUP BY 
        p.Id
),
HighRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AcceptedAnswerId,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
        AND EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2)
),
CloseReasonVotes AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseVoteCount,
        STRING_AGG(CAST(ph.Comment AS VARCHAR), ', ') AS CloseReasons
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostsWithCloseReasons AS (
    SELECT 
        hrp.PostId,
        hrp.Title,
        hrp.CreationDate,
        hrp.ViewCount,
        hrp.Score,
        hrp.CommentCount,
        COALESCE(cr.CloseVoteCount, 0) AS CloseVoteCount,
        COALESCE(cr.CloseReasons, 'No close reasons') AS CloseReasons
    FROM 
        HighRankedPosts hrp
    LEFT JOIN 
        CloseReasonVotes cr ON hrp.PostId = cr.PostId
)
SELECT 
    pwr.PostId,
    pwr.Title,
    pwr.CreationDate,
    pwr.ViewCount,
    pwr.Score,
    pwr.CommentCount,
    CASE 
        WHEN pwr.CloseVoteCount > 5 THEN 'Highly contested'
        WHEN pwr.CloseVoteCount > 0 THEN 'Some contention'
        ELSE 'No contention'
    END AS ContentionStatus,
    CASE 
        WHEN pwr.Score = 0 THEN 'Neutral'
        WHEN pwr.Score > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS SentimentScore
FROM 
    PostsWithCloseReasons pwr
WHERE 
    pwr.Score IS NOT NULL 
    AND pwr.ViewCount > 100
ORDER BY 
    pwr.ViewCount DESC, 
    pwr.Score DESC;