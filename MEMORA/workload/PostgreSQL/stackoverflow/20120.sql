
WITH UserVoteCounts AS (
    SELECT 
        UserId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes 
    FROM Votes 
    GROUP BY UserId
), 
PostEditHistory AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN PostHistoryTypeId IN (4, 5, 6) THEN CreationDate END) AS LastEditDate,
        COUNT(CASE WHEN PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM PostHistory ph
    GROUP BY ph.PostId
), 
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    JOIN UserVoteCounts uvc ON uvc.UserId = u.Id
    WHERE uvc.TotalVotes > 0
), 
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p 
    WHERE p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
)

SELECT 
    TOP.Title,
    TOP.CreationDate,
    TOP.ViewCount,
    COALESCE(uh.UpVotes, 0) AS UpVotes,
    COALESCE(uh.DownVotes, 0) AS DownVotes,
    pe.LastEditDate,
    CASE 
        WHEN pe.CloseCount > 0 THEN 'Closed' 
        WHEN pe.ReopenCount > 0 THEN 'Reopened' 
        ELSE 'Active' 
    END AS PostStatus,
    CONCAT(u.DisplayName, CASE WHEN u.DisplayName IS NOT NULL THEN CONCAT(' (+', u.Reputation, ')') ELSE '' END) AS UserWithReputation
FROM TopPosts TOP
LEFT JOIN PostEditHistory pe ON TOP.PostId = pe.PostId
LEFT JOIN UserVoteCounts uh ON uh.UserId = (
    SELECT OwnerUserId 
    FROM Posts 
    WHERE Id = TOP.PostId
)
LEFT JOIN MostActiveUsers u ON u.UserId = uh.UserId
WHERE 
    (uh.TotalVotes IS NULL OR uh.TotalVotes > 4)
    AND (TOP.ScoreRank <= 10 OR TOP.Score IS NOT NULL)
ORDER BY TOP.Score DESC, TOP.CreationDate DESC
LIMIT 20 OFFSET 0;
