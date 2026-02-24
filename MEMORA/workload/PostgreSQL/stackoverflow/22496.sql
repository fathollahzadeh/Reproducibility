
WITH UserRankings AS (
    SELECT 
        Id AS UserId, 
        DisplayName, 
        Reputation, 
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS Rank 
    FROM Users 
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END), NULL) AS ClosedDate,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END), NULL) AS DeletedDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.OwnerUserId, p.CreationDate
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT pa.PostId) AS ActivePostCount,
        AVG(COALESCE(pa.CommentCount, 0)) AS AvgCommentCount
    FROM Users u
    JOIN PostActivity pa ON u.Id = pa.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostInsights AS (
    SELECT 
        pa.PostId,
        pa.OwnerUserId,
        pa.CommentCount,
        pa.UpVoteCount,
        pa.DownVoteCount,
        pa.ClosedDate,
        pa.DeletedDate,
        ROW_NUMBER() OVER (ORDER BY pa.UpVoteCount DESC, pa.CommentCount DESC) AS PostRank
    FROM PostActivity pa
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Rank,
    au.ActivePostCount,
    au.AvgCommentCount,
    pi.PostId,
    pi.CommentCount,
    pi.UpVoteCount,
    pi.DownVoteCount,
    CASE 
        WHEN pi.ClosedDate IS NOT NULL THEN 'Closed'
        WHEN pi.DeletedDate IS NOT NULL THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus
FROM UserRankings ur
LEFT JOIN ActiveUsers au ON ur.UserId = au.UserId
LEFT JOIN PostInsights pi ON au.UserId = pi.OwnerUserId
WHERE ur.Rank <= 100
      AND au.ActivePostCount > 0
ORDER BY ur.Rank, pi.UpVoteCount DESC;
