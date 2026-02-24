WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
UserVotes AS (
    SELECT 
        v.PostId, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
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
    rp.AnswerCount,
    rp.CommentCount,
    COALESCE(uv.Upvotes, 0) AS UpvoteCount,
    COALESCE(uv.Downvotes, 0) AS DownvoteCount,
    CASE 
        WHEN rp.RankByScore <= 5 THEN 'Top 5 in Score'
        WHEN rp.RankByViews <= 5 THEN 'Top 5 in Views'
        ELSE 'Other'
    END AS RankCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVotes uv ON rp.PostId = uv.PostId
WHERE 
    rp.RankByScore <= 10 OR rp.RankByViews <= 10
ORDER BY 
    RankCategory, rp.Score DESC, rp.ViewCount DESC;