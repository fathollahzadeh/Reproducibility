WITH RECURSIVE UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalVotes,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank
    FROM UserVoteCounts
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(voteCounts.UpVotes, 0) AS UpVotes,
        COALESCE(voteCounts.DownVotes, 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.UserId) AS BadgeCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN (
        SELECT PostId, 
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
        FROM Votes 
        GROUP BY PostId
    ) AS voteCounts ON p.Id = voteCounts.PostId
    WHERE p.OwnerUserId IS NOT NULL
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, voteCounts.UpVotes, voteCounts.DownVotes
),
RankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        UpVotes,
        DownVotes,
        CommentCount,
        BadgeCount,
        RANK() OVER (ORDER BY Score DESC, CreationDate DESC) AS PostRank
    FROM PostStatistics
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        rp.BadgeCount
    FROM RankedPosts rp
    WHERE rp.PostRank <= 50
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.UpVotes,
    fp.DownVotes,
    fp.CommentCount,
    u.DisplayName AS PostOwner,
    CASE 
        WHEN fp.BadgeCount > 0 THEN 'Has Badges' 
        ELSE 'No Badges' 
    END AS BadgeStatus,
    CASE 
        WHEN fp.Score > 10 THEN 'High Score' 
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM FilteredPosts fp
LEFT JOIN Users u ON fp.PostId = u.Id
ORDER BY fp.Score DESC, fp.CreationDate DESC;
