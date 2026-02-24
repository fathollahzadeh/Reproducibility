
WITH RecursiveUserVotes AS (
    SELECT
        v.PostId,
        v.UserId,
        ROW_NUMBER() OVER (PARTITION BY v.PostId ORDER BY v.CreationDate DESC) AS VoteRank
    FROM Votes v
    WHERE v.VoteTypeId IN (2, 3) 
),
PostScoreHistory AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.Score
),
ActiveUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS BadgeScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 50
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
RankedPosts AS (
    SELECT
        psh.PostId,
        psh.Title,
        psh.Score,
        psh.UpVotes,
        psh.DownVotes,
        psh.CommentCount,
        psh.LastHistoryDate,
        RANK() OVER (ORDER BY psh.Score DESC, psh.CommentCount DESC) AS PostRank
    FROM PostScoreHistory psh
)
SELECT
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.CreationDate,
    rps.PostId,
    rps.Title,
    rps.Score,
    rps.UpVotes,
    rps.DownVotes,
    rps.CommentCount,
    rps.PostRank
FROM ActiveUsers up
JOIN RankedPosts rps ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rps.PostId)
WHERE rps.PostRank <= 100
ORDER BY up.Reputation DESC, rps.Score DESC;
