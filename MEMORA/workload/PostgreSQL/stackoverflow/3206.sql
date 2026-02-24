
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.Comment,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName
    FROM PostHistory ph
    WHERE ph.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
SubQueryVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
)

SELECT 
    rnd.Id AS PostId,
    rnd.Title,
    u.DisplayName AS Owner,
    us.TotalUpVotes,
    us.TotalDownVotes,
    rnd.Score,
    rnd.ViewCount,
    rnd.AnswerCount,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(ph.PostHistoryTypeId, 0) AS LastHistoryAction,
    COALESCE(ph.Comment, 'No recent history') AS LastHistoryComment,
    DENSE_RANK() OVER (ORDER BY COALESCE(rnd.Score, 0) DESC) AS Rank
FROM RankedPosts rnd
JOIN Users u ON rnd.OwnerUserId = u.Id
JOIN UserStats us ON u.Id = us.UserId
LEFT JOIN SubQueryVotes vs ON rnd.Id = vs.PostId
LEFT JOIN PostHistoryDetails ph ON rnd.Id = ph.PostId AND ph.HistoryDate = (SELECT MAX(HistoryDate) FROM PostHistoryDetails WHERE PostId = rnd.Id)
ORDER BY Rank, rnd.Score DESC;
