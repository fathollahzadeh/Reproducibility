
WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS TotalCommentCount,
        AVG(vote.VoteTypeId) AS AvgVoteType
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vote ON p.Id = vote.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount, u.Reputation
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS RevisionCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPosts,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedPosts
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.TotalCommentCount,
    ps.FavoriteCount,
    ps.OwnerReputation,
    pht.RevisionCount,
    pht.LastEditDate,
    pht.ClosedPosts,
    pht.ReopenedPosts
FROM 
    PostSummary ps
LEFT JOIN 
    PostHistoryStats pht ON ps.PostId = pht.PostId
ORDER BY 
    ps.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
