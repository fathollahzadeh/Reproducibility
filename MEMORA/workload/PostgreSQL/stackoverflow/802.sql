WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVotesCount,
        ps.DownVotesCount,
        ROW_NUMBER() OVER (ORDER BY ps.UpVotesCount DESC, ps.CommentCount DESC) AS Rank
    FROM PostSummary ps
)
SELECT 
    tp.Title AS PostTitle,
    tp.CreationDate AS PostDate,
    u.DisplayName AS PostOwner,
    tp.CommentCount,
    tp.UpVotesCount,
    tp.DownVotesCount,
    CASE 
        WHEN tp.UpVotesCount + tp.DownVotesCount = 0 THEN NULL
        ELSE (tp.UpVotesCount * 1.0 / (tp.UpVotesCount + tp.DownVotesCount)) * 100
    END AS UpVotePercentage,
    COALESCE(b.Name, 'No Badge') AS UserBadge
FROM TopPosts tp
LEFT JOIN Users u ON tp.OwnerUserId = u.Id
LEFT JOIN Badges b ON u.Id = b.UserId AND b.Class = 1 
WHERE tp.Rank <= 5
ORDER BY tp.UpVotesCount DESC;