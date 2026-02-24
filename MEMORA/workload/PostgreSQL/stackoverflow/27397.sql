
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.CreationDate,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate, p.OwnerUserId
),
PopularPosts AS (
    SELECT 
        ap.PostId,
        ap.Title,
        ap.ViewCount,
        ap.CommentCount,
        ap.UpVotes,
        ap.DownVotes,
        ap.CreationDate,
        ru.DisplayName AS OwnerDisplayName,
        ru.Reputation AS OwnerReputation
    FROM ActivePosts ap
    JOIN RankedUsers ru ON ap.OwnerUserId = ru.UserId
    WHERE ap.UpVotes - ap.DownVotes > 5
    ORDER BY ap.ViewCount DESC
    LIMIT 10
)
SELECT
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.CommentCount,
    pp.UpVotes,
    pp.DownVotes,
    pp.CreationDate,
    pp.OwnerDisplayName,
    pp.OwnerReputation
FROM PopularPosts pp
JOIN PostHistory ph ON pp.PostId = ph.PostId
WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
ORDER BY pp.CreationDate DESC;
