WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.PostTypeId,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(
            SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id),
            0
        ) AS Upvotes,
        COALESCE(
            SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id),
            0
        ) AS Downvotes,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT ph.Comment) AS CommentsAboutChanges,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) 
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        rp.Rank,
        rp.Upvotes,
        rp.Downvotes,
        rp.CommentCount,
        COALESCE(pha.CommentsAboutChanges, '{}') AS CommentsAboutChanges,
        pha.HistoryCount,
        pha.LastHistoryDate,
        CASE 
            WHEN rp.Score > 100 THEN 'Popular'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderate'
            WHEN rp.Score < 50 THEN 'Less Popular'
            ELSE 'Unknown'
        END AS Popularity
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryAggregated pha ON rp.PostId = pha.PostId
    WHERE 
        rp.Rank = 1
)
SELECT 
    PostId,
    Title,
    ViewCount,
    Score,
    CreationDate,
    Upvotes,
    Downvotes,
    CommentCount,
    CommentsAboutChanges,
    HistoryCount,
    LastHistoryDate,
    Popularity
FROM 
    FinalResults
ORDER BY 
    Score DESC, 
    ViewCount DESC NULLS LAST
LIMIT 50;