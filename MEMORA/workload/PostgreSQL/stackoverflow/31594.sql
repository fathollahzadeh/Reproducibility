
WITH RECURSIVE UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY ph.PostId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        cr.Name AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN CloseReasonTypes cr ON CAST(ph.Comment AS int) = cr.Id
    WHERE ph.PostHistoryTypeId = 10 
),
RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(ps.EditCount, 0) AS EditCount,
        COALESCE(cp.ClosedDate, NULL) AS ClosedDate,
        COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN PostHistorySummary ps ON p.Id = ps.PostId
    LEFT JOIN ClosedPosts cp ON p.Id = cp.PostId
    WHERE p.OwnerUserId IS NOT NULL
)
SELECT 
    ue.DisplayName,
    ue.Reputation,
    ue.PostCount,
    ue.UpVotes,
    ue.DownVotes,
    rp.Title,
    rp.CreationDate,
    rp.EditCount,
    rp.ClosedDate,
    rp.CloseReason
FROM UserEngagement ue
JOIN RankedPosts rp ON ue.UserId = rp.OwnerUserId
WHERE rp.PostRank = 1 
ORDER BY ue.UserRank, rp.CreationDate DESC;
