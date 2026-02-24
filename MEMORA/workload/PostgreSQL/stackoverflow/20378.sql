
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN u.Reputation >= 1000 THEN 'High'
            WHEN u.Reputation >= 100 THEN 'Medium'
            ELSE 'Low' 
        END ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
),
RecentActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 DAYS') 
    GROUP BY p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.ViewCount
),
PostVoteStatistics AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        p.Title,
        t.TagName
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    JOIN Tags t ON t.ExcerptPostId = p.Id
    WHERE ph.PostHistoryTypeId = 10
)
SELECT 
    u.DisplayName,
    ur.Reputation,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    rp.CommentCount,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Commented'
        ELSE 'No Comments' 
    END AS CommentStatus,
    ROW_NUMBER() OVER (PARTITION BY ur.Rank ORDER BY rp.ViewCount DESC) AS MostViewedRank
FROM UserReputation ur
JOIN Users u ON ur.UserId = u.Id
JOIN RecentActivePosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN PostVoteStatistics pvs ON rp.PostId = pvs.PostId
WHERE ur.Reputation > (SELECT AVG(Reputation) FROM Users) 
  AND EXISTS (SELECT 1 FROM ClosedPostDetails cp WHERE cp.PostId = rp.PostId)
ORDER BY 
    ur.Rank DESC, 
    rp.ViewCount DESC,
    u.DisplayName;
