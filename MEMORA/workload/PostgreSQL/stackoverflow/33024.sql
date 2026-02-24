WITH RecursiveTopPosts AS (
    SELECT p.Id, p.Title, p.OwnerUserId, p.ViewCount, p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1  
),
UserStats AS (
    SELECT u.Id AS UserId, 
           COUNT(DISTINCT p.Id) AS PostCount, 
           SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
           SUM(COALESCE(CASE WHEN p.Score > 0 THEN p.Score END, 0)) AS PositiveScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
VoteSummary AS (
    SELECT p.Id AS PostId, 
           COUNT(v.Id) AS TotalVotes, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT p.Id, p.Title, ph.CreationDate AS ClosedDate,
           pr.Name AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN CloseReasonTypes pr ON CAST(ph.Comment AS int) = pr.Id
    WHERE ph.PostHistoryTypeId = 10  
),
UserBadges AS (
    SELECT u.Id AS UserId, 
           STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
FinalReport AS (
    SELECT us.UserId, 
           u.DisplayName,
           us.PostCount,
           us.TotalViews,
           us.PositiveScore,
           COALESCE(tp.Title, 'No Top Post') AS TopPostTitle,
           COALESCE(cb.CloseReason, 'Not Closed') AS PostCloseReason,
           ub.BadgeNames
    FROM UserStats us
    LEFT JOIN Users u ON us.UserId = u.Id
    LEFT JOIN RecursiveTopPosts tp ON us.UserId = tp.OwnerUserId AND tp.rn = 1
    LEFT JOIN ClosedPosts cb ON cb.Id = (SELECT MAX(Id) FROM Posts WHERE OwnerUserId = us.UserId)
    LEFT JOIN UserBadges ub ON us.UserId = ub.UserId
)
SELECT fr.UserId, 
       fr.DisplayName,
       fr.PostCount,
       fr.TotalViews,
       fr.PositiveScore,
       fr.TopPostTitle,
       fr.PostCloseReason,
       COALESCE(fr.BadgeNames, 'No Badges') AS BadgeNames
FROM FinalReport fr
ORDER BY fr.TotalViews DESC, fr.PostCount DESC;