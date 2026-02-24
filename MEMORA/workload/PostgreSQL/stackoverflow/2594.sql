
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(v.BountyAmount) AS AverageBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId, p.Score, p.ViewCount
),
RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.Score DESC) AS PostRank
    FROM PostStats ps
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.ClosedDate,
        h.UserDisplayName AS ClosedBy,
        h.CreationDate AS ClosureDate,
        h.Comment AS CloseReason 
    FROM Posts p
    JOIN PostHistory h ON p.Id = h.PostId
    WHERE h.PostHistoryTypeId = 10
),
FinalResults AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        COALESCE(rp.PostId, -1) AS RecentPostId,
        COALESCE(rp.Score, 0) AS RecentPostScore,
        COALESCE(cp.ClosedBy, 'Not Closed') AS PostClosedBy,
        COALESCE(cp.CloseReason, 'N/A') AS ClosureReason,
        us.AverageBounty
    FROM UserStats us
    LEFT JOIN RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.PostRank = 1
    LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    *,
    CASE 
        WHEN Reputation > 1000 THEN 'High Reputation'
        WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM FinalResults
WHERE TotalPosts > 0
ORDER BY TotalPosts DESC, Reputation DESC;
