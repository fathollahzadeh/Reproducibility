
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        CASE 
            WHEN COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) > COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) THEN 'Positive'
            WHEN COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) > COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(DISTINCT c.Id) DESC) AS RankByComments
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        COALESCE(cr.Name, 'Unknown') AS CloseReason
    FROM PostHistory ph
    LEFT JOIN CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) 
),
UserDescriptor AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        CASE 
            WHEN u.Reputation > 10000 THEN 'Elite'
            WHEN u.Reputation BETWEEN 1000 AND 10000 THEN 'Experienced'
            ELSE 'Novice'
        END AS UserLevel
    FROM Users u
)

SELECT 
    um.DisplayName AS UserName,
    um.TotalPosts,
    um.TotalComments,
    um.UpVotes AS UserUpVotes,
    um.DownVotes AS UserDownVotes,
    ps.Title AS PostTitle,
    ps.CommentCount,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    ps.VoteSentiment,
    cp.CloseDate,
    cp.CloseReason,
    ud.UserLevel
FROM UserMetrics um
JOIN PostStatistics ps ON um.UserId = ps.PostId 
LEFT JOIN ClosedPosts cp ON cp.PostId = ps.PostId 
JOIN UserDescriptor ud ON um.UserId = ud.UserId
WHERE (um.TotalPosts > 5 OR um.TotalComments > 10) 
AND ps.RankByComments <= 3 
ORDER BY um.Reputation DESC, ps.CommentCount DESC
LIMIT 100;
