WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.ViewCount > 100
),
ClosedPostCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseReasonCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.Rank,
        rpc.CloseReasonCount,
        (rp.Upvotes - rp.Downvotes) AS NetVotes,
        CASE 
            WHEN rpc.CloseReasonCount > 0 THEN 'Closed'
            WHEN rp.Rank <= 3 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPostCounts rpc ON rp.PostId = rpc.PostId
)
SELECT 
    PostId, 
    Title, 
    ViewCount, 
    Score, 
    Rank, 
    CloseReasonCount, 
    NetVotes, 
    PostCategory
FROM 
    FinalResults
WHERE 
    PostCategory = 'Top Post' OR CloseReasonCount > 0
ORDER BY 
    NetVotes DESC, 
    ViewCount DESC;