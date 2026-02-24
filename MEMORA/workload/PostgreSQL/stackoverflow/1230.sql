WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND 
        (u.Reputation > 100 OR u.Location IS NOT NULL)
), 
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        CASE 
            WHEN rp.UpvoteCount > rp.DownvoteCount THEN 'Positive'
            WHEN rp.UpvoteCount < rp.DownvoteCount THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSummary,
        CASE 
            WHEN rp.Score > 10 THEN 'High Score'
            WHEN rp.Score BETWEEN 1 AND 10 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
), 
AggregatedStats AS (
    SELECT 
        PS.ScoreCategory,
        COUNT(*) AS PostCount,
        AVG(PS.ViewCount) AS AverageViews,
        SUM(PS.CommentCount) AS TotalComments
    FROM 
        PostStatistics PS
    GROUP BY 
        PS.ScoreCategory
)
SELECT 
    PS.ScoreCategory,
    PS.PostCount,
    PS.AverageViews,
    PS.TotalComments,
    'Type: ' || PS.ScoreCategory || ' Posts' AS CategoryDescription
FROM 
    AggregatedStats PS
ORDER BY 
    PS.PostCount DESC
LIMIT 10;