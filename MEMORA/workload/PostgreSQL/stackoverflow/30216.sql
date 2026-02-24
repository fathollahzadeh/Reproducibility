WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        COUNT(DISTINCT v.Id) AS VotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureStatus, 
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostId IN (SELECT DISTINCT PostId FROM RankedPosts)
    GROUP BY ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ua.QuestionsAsked,
    ua.CommentsMade,
    ua.VotesReceived,
    ua.UpVotesReceived,
    ua.DownVotesReceived,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(p.CloseVotes, 0) AS CloseVotes,
    COALESCE(p.ClosureStatus, 0) AS ClosureStatus,
    p.LastEditDate
FROM UserActivity ua
JOIN Users u ON u.Id = ua.UserId
LEFT JOIN RankedPosts rp ON rp.OwnerUserId = u.Id
LEFT JOIN PostHistoryDetails p ON p.PostId = rp.PostId
WHERE ua.Reputation > 1000 
AND COALESCE(p.ClosureStatus, 0) < 1 
ORDER BY ua.Reputation DESC, rp.CreationDate DESC;