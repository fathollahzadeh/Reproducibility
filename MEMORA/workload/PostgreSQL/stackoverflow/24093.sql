WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COALESCE(vs.VoteScore, 0) AS TotalVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(vs.VoteScore, 0) DESC) AS RankByVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 
                     WHEN VoteTypeId = 3 THEN -1 
                     ELSE 0 END) AS VoteScore
        FROM 
            Votes
        GROUP BY 
            PostId
    ) vs ON p.Id = vs.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason,
        MIN(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS CloseDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        STRING_AGG(t.TagName, ', ') AS TagsAgg
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Tags t ON rp.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        rp.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.TotalVotes,
    COALESCE(pcr.CloseReason, 'Not Closed') AS CloseReason,
    COALESCE(rp.RankByVotes, 0) AS VoteRank,
    tp.TagsAgg,
    rp.CreationDate,
    DENSE_RANK() OVER (ORDER BY rp.TotalVotes DESC, rp.CreationDate) AS OverallRank,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No Views Recorded'
        WHEN rp.ViewCount >= 1000 THEN 'High Traffic'
        WHEN rp.ViewCount BETWEEN 100 AND 999 THEN 'Moderate Traffic'
        ELSE 'Low Traffic' 
    END AS TrafficCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostCloseReasons pcr ON rp.PostId = pcr.PostId
LEFT JOIN 
    TaggedPosts tp ON rp.PostId = tp.PostId
WHERE 
    rp.RankByVotes <= 3 OR rp.CommentCount > 5
ORDER BY 
    rp.RankByVotes, rp.CreationDate DESC;