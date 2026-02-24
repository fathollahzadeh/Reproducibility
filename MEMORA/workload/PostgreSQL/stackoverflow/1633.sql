
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId, p.CreationDate, p.Title
),
TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        r.DisplayName AS OwnerDisplayName,
        rp.CommentCount,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'Hot'
            WHEN rp.CommentCount > 5 THEN 'Trending'
            ELSE 'Normal'
        END AS PostStatus
    FROM RecentPosts rp
    JOIN RankedUsers r ON rp.OwnerUserId = r.UserId
    WHERE r.Rank <= 100
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),
FinalBenchmark AS (
    SELECT 
        p.PostId,
        p.Title,
        p.OwnerDisplayName,
        p.CommentCount,
        pv.UpVotes,
        pv.DownVotes,
        p.PostStatus,
        COALESCE(pv.UpVotes - pv.DownVotes, 0) AS NetVotes,
        CASE 
            WHEN p.CommentCount IS NULL THEN 'No Comments'
            ELSE CONCAT(p.CommentCount, ' Comments')
        END AS CommentSummary
    FROM TopPostDetails p
    LEFT JOIN PostVoteCounts pv ON p.PostId = pv.PostId
)
SELECT 
    f.PostId,
    f.Title,
    f.OwnerDisplayName,
    f.CommentSummary,
    f.UpVotes,
    f.DownVotes,
    f.NetVotes,
    f.PostStatus
FROM FinalBenchmark f
ORDER BY f.NetVotes DESC, f.CommentCount DESC
LIMIT 50;
