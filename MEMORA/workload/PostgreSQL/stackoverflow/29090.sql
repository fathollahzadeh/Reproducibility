WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Body,
        u.DisplayName AS AuthorDisplayName,
        COALESCE(NULLIF(p.Score, 0), NULL) AS Score,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenedCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')::varchar[] @> ARRAY[t.TagName]
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName
),
Benchmark AS (
    SELECT 
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore,
        COUNT(PostId) AS TotalPosts,
        SUM(CommentCount) AS TotalComments,
        SUM(UpvoteCount) AS TotalUpvotes,
        SUM(CloseReopenedCount) AS TotalCloseReopened
    FROM
        PostDetails
)
SELECT 
    bd.*,
    pd.TagsList
FROM 
    Benchmark bd
JOIN 
    PostDetails pd ON pd.Score >= bd.AvgScore 
ORDER BY 
    pd.ViewCount DESC
LIMIT 10;
