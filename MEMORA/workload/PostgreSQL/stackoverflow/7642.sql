
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN vt.VoteTypeId = 2 THEN vt.Id END) AS UpvoteCount,
        COUNT(DISTINCT CASE WHEN vt.VoteTypeId = 3 THEN vt.Id END) AS DownvoteCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS RankByScore,
        RANK() OVER (ORDER BY CommentCount DESC, CreationDate DESC) AS RankByComments
    FROM 
        PostStats
)
SELECT 
    PostId,
    Title,
    CreationDate,
    OwnerDisplayName,
    Score,
    ViewCount,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    RelatedPostsCount,
    RankByScore,
    RankByComments
FROM 
    TopPosts
WHERE 
    RankByScore <= 10 OR RankByComments <= 10
ORDER BY 
    RankByScore, RankByComments;
