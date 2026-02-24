WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score > 0
),
AggregatedVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.UserId) AS CloseVotesCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(av.Upvotes, 0) AS Upvotes,
    COALESCE(av.Downvotes, 0) AS Downvotes,
    COALESCE(av.TotalVotes, 0) AS TotalVotes,
    COALESCE(cp.CloseVotesCount, 0) AS CloseVotesCount,
    (rp.ViewCount - COALESCE(cp.CloseVotesCount, 0)) AS ViewCountAfterClose,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Top Post for User'
        WHEN rp.UserPostRank BETWEEN 2 AND 5 THEN 'High Ranking Post'
        ELSE 'Regular Post'
    END AS PostStatus,
    CASE
        WHEN rp.Score > 100 THEN 'Hot Post'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS Popularity
FROM 
    RankedPosts rp
LEFT JOIN 
    AggregatedVotes av ON rp.PostId = av.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Score NOT IN (SELECT Score FROM Posts WHERE Score < 0) 
    AND rp.ViewCount IS NOT NULL
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC;