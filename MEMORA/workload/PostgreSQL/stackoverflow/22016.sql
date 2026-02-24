
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        STRING_AGG(ph.Comment, ', ') AS Comments,
        COUNT(*) AS EditCount
    FROM PostHistory ph
    WHERE ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '90 days' 
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
UserPostSummary AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        COUNT(ap.PostId) AS TotalPosts,
        COALESCE(SUM(phd.EditCount), 0) AS TotalEdits,
        SUM(ap.CommentCount) AS TotalComments,
        SUM(ap.UpVotes) AS TotalUpVotes,
        SUM(ap.DownVotes) AS TotalDownVotes
    FROM UserReputation ur
    LEFT JOIN ActivePosts ap ON ur.UserId = ap.OwnerUserId
    LEFT JOIN PostHistoryData phd ON ap.PostId = phd.PostId
    GROUP BY ur.UserId, ur.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalEdits,
    us.TotalComments,
    us.TotalUpVotes,
    us.TotalDownVotes,
    CASE 
        WHEN us.TotalUpVotes > us.TotalDownVotes THEN 'Positive Engagement'
        WHEN us.TotalDownVotes > us.TotalUpVotes THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementType,
    ur.ReputationRank
FROM UserPostSummary us
JOIN UserReputation ur ON us.UserId = ur.UserId
WHERE us.TotalPosts > 0
ORDER BY us.TotalPosts DESC, us.TotalComments DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
