WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2020-01-01'
        AND p.Score IS NOT NULL
),
EnhancedPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        OwnerName,
        RankScore,
        CASE 
            WHEN RankScore <= 10 THEN 'Top'
            WHEN RankScore BETWEEN 11 AND 100 THEN 'Intermediate'
            ELSE 'Low'
        END AS PerformanceCategory
    FROM 
        RankedPosts
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(*) FILTER (WHERE VoteTypeId = 2) AS Upvotes,
        COUNT(*) FILTER (WHERE VoteTypeId = 3) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 1 THEN ph.CreationDate END) AS InitialTitleDate,
        MIN(CASE WHEN ph.PostHistoryTypeId = 2 THEN ph.CreationDate END) AS InitialBodyDate,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    ep.PostId,
    ep.Title,
    ep.ViewCount,
    ep.Score,
    ep.OwnerName,
    ep.PerformanceCategory,
    COALESCE(pvc.Upvotes, 0) AS TotalUpvotes,
    COALESCE(pvc.Downvotes, 0) AS TotalDownvotes,
    ph.InitialTitleDate,
    ph.InitialBodyDate,
    ph.ClosedDate,
    CASE 
        WHEN ph.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN ep.PerformanceCategory = 'Top' AND ph.ClosedDate IS NOT NULL THEN 'Highly active post that got closed. Review required.'
        WHEN ep.PerformanceCategory = 'Low' AND ph.ClosedDate IS NULL THEN 'Needs attention for improvement.'
        ELSE 'Regular post.'
    END AS StatusMessage
FROM 
    EnhancedPosts ep
LEFT JOIN 
    PostVoteCounts pvc ON ep.PostId = pvc.PostId
LEFT JOIN 
    PostHistoryData ph ON ep.PostId = ph.PostId
WHERE 
    ep.RankScore <= 100
ORDER BY 
    ep.Score DESC NULLS LAST, 
    ep.ViewCount ASC;
