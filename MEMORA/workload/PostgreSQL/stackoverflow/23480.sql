
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS DeleteVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 8 THEN v.BountyAmount ELSE 0 END), 0) AS BountyTotal
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment AS EditComment,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (4, 5, 6)) AS EditCount,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.UserId, ph.CreationDate, ph.Comment
),
PostAggregate AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(pd.EditCount, 0) AS TotalEdits,
        COALESCE(pd.CloseCount, 0) AS TotalCloses,
        uvs.UpvoteCount,
        uvs.DownvoteCount,
        uvs.DeleteVoteCount,
        uvs.BountyTotal,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN PostHistoryDetail pd ON p.Id = pd.PostId
    LEFT JOIN UserVoteStats uvs ON p.OwnerUserId = uvs.UserId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.ViewCount,
    pa.TotalEdits,
    pa.TotalCloses,
    pa.UpvoteCount,
    pa.DownvoteCount,
    pa.DeleteVoteCount,
    pa.BountyTotal,
    CASE 
        WHEN pa.TotalCloses > 0 THEN 'Closed'
        WHEN pa.TotalEdits > 10 THEN 'Frequently Edited'
        WHEN pa.UpvoteCount > pa.DownvoteCount THEN 'Positive Sentiment'
        ELSE 'Needs Attention' 
    END AS PostStatus,
    STRING_AGG(CASE 
        WHEN b.Class = 1 THEN 'Gold: ' || b.Name 
        WHEN b.Class = 2 THEN 'Silver: ' || b.Name 
        WHEN b.Class = 3 THEN 'Bronze: ' || b.Name 
        ELSE NULL END, ', ') AS UserBadges
FROM PostAggregate pa
LEFT JOIN Badges b ON pa.OwnerUserId = b.UserId
GROUP BY pa.PostId, pa.Title, pa.ViewCount, pa.TotalEdits, pa.TotalCloses, 
         pa.UpvoteCount, pa.DownvoteCount, pa.DeleteVoteCount, pa.BountyTotal, 
         pa.OwnerUserId
ORDER BY pa.ViewCount DESC
LIMIT 10;
