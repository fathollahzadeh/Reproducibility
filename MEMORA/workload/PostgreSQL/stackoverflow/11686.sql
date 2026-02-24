
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        PH.PHCount,
        COALESCE(AVG(v.BountyAmount), 0) AS AvgBounty
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS PHCount
        FROM PostHistory
        GROUP BY PostId
    ) PH ON p.Id = PH.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, 
             u.DisplayName, u.Reputation, PH.PHCount
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    AnswerCount,
    CommentCount,
    OwnerDisplayName,
    OwnerReputation,
    PHCount,
    AvgBounty,
    RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank,
    RANK() OVER (ORDER BY Score DESC) AS ScoreRank
FROM PostMetrics
ORDER BY ViewCount DESC, Score DESC;
