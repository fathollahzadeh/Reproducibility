WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score IS NOT NULL
),
FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        OwnerName
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 5
),
PostMetrics AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.OwnerName,
        fp.CreationDate,
        COALESCE(NULLIF(fp.ViewCount, 0), 1) AS ViewCount, 
        CASE 
            WHEN fp.Score IS NULL THEN 0
            ELSE fp.Score 
        END AS AdjustedScore,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = fp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        FilteredPosts fp
),
AggregatedMetrics AS (
    SELECT 
        OwnerName,
        SUM(AdjustedScore) AS TotalScore,
        SUM(ViewCount) AS TotalViews,
        SUM(CommentCount) AS TotalComments,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        PostMetrics
    GROUP BY 
        OwnerName
)
SELECT 
    OwnerName,
    TotalScore,
    TotalViews,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    CASE 
        WHEN TotalViews > 0 THEN (TotalUpVotes * 100.0 / TotalViews) 
        ELSE NULL 
    END AS UpVotePercentage,
    CASE 
        WHEN TotalComments > 0 THEN (TotalScore * 1.0 / TotalComments) 
        ELSE NULL 
    END AS ScorePerComment
FROM 
    AggregatedMetrics
WHERE 
    TotalScore > 0
ORDER BY 
    TotalScore DESC 
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;