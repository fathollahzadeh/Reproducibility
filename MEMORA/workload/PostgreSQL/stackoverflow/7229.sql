WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS ViewCountRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate, p.Score, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        VoteCount,
        ScoreRank,
        ViewCountRank
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10 OR ViewCountRank <= 10
),
PostAggregates AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AvgScore,
        AVG(ViewCount) AS AvgViewCount,
        SUM(CommentCount) AS TotalComments,
        SUM(VoteCount) AS TotalVotes
    FROM 
        FilteredPosts
)
SELECT 
    fp.*,
    pa.TotalPosts,
    pa.AvgScore,
    pa.AvgViewCount,
    pa.TotalComments,
    pa.TotalVotes
FROM 
    FilteredPosts fp
CROSS JOIN 
    PostAggregates pa
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;