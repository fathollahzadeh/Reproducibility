
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        AVG(EXTRACT(EPOCH FROM (u.LastAccessDate - u.CreationDate))) AS AvgActiveDuration
    FROM Users u
    LEFT JOIN Badges b ON b.UserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.Reputation
),
PostAggregates AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        AVG(p.Score) AS AvgPostScore
    FROM Posts p
    LEFT JOIN Votes v ON v.PostId = p.Id
    GROUP BY p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.UserId,
        COUNT(DISTINCT p.Id) AS ClosedPostCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS TotalClosed,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS TotalReopened
    FROM PostHistory ph
    JOIN Posts p ON p.Id = ph.PostId
    WHERE p.PostTypeId = 1 AND ph.PostHistoryTypeId IN (10, 11)
    GROUP BY ph.UserId
),
FinalResult AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.BadgeCount,
        ur.TotalBounty,
        pa.QuestionCount,
        pa.AnswerCount,
        pa.UpVotes,
        pa.DownVotes,
        cp.ClosedPostCount,
        cp.TotalClosed,
        cp.TotalReopened,
        CASE 
            WHEN ur.Reputation > 1000 THEN 'High Reputation'
            WHEN ur.Reputation > 500 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory,
        CASE 
            WHEN cp.TotalClosed > cp.TotalReopened THEN 'More Closed'
            ELSE 'Reopened or Balanced'
        END AS ClosingStatus,
        ROW_NUMBER() OVER (ORDER BY ur.TotalBounty DESC, ur.BadgeCount DESC) AS Rank
    FROM UserReputation ur
    LEFT JOIN PostAggregates pa ON ur.UserId = pa.OwnerUserId
    LEFT JOIN ClosedPosts cp ON ur.UserId = cp.UserId
    WHERE ur.Reputation IS NOT NULL
)
SELECT 
    UserId, Reputation, BadgeCount, TotalBounty, 
    QuestionCount, AnswerCount, UpVotes, DownVotes,
    ClosedPostCount, TotalClosed, TotalReopened,
    ReputationCategory, ClosingStatus, Rank
FROM FinalResult
WHERE TotalBounty > 50
ORDER BY Rank;
