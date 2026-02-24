
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(NULLIF(p.Tags, ''), 'No Tags') AS SafeTags,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.Tags
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        CPR.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes CPR ON CAST(ph.Comment AS INTEGER) = CPR.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
),
AggregatedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 5) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    upvotes.UpVotes,
    downvotes.DownVotes,
    COALESCE(cp.CloseReason, 'Not Closed') AS CloseStatus,
    CASE 
        WHEN rp.Score > 0 THEN 'Active'
        WHEN rp.Score = 0 AND upvotes.UpVotes > downvotes.DownVotes THEN 'Neutral'
        WHEN rp.Score < 0 THEN 'Negative'
        ELSE 'Unrated'
    END AS PostStatus,
    STRING_AGG(rp.SafeTags, ', ') AS TagsList
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    AggregatedVotes upvotes ON rp.PostId = upvotes.PostId
LEFT JOIN 
    AggregatedVotes downvotes ON rp.PostId = downvotes.PostId
WHERE 
    rp.PostRank <= 5 
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.CommentCount, 
    upvotes.UpVotes, downvotes.DownVotes, cp.CloseReason
ORDER BY 
    rp.CreationDate DESC;
