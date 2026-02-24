
WITH UserVoteStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT v.PostId) AS TotalVotes,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN
            (SELECT cr.Name FROM CloseReasonTypes cr WHERE cr.Id = CAST(ph.Comment AS INTEGER)) 
        END AS CloseReasonName
    FROM PostHistory ph
),
PostsWithVotes AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.CreationDate
)
SELECT
    uvs.UserId,
    uvs.DisplayName,
    uvs.UpVotes,
    uvs.DownVotes,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    CASE WHEN phd.CloseReasonName IS NOT NULL THEN 'Closed due to: ' || phd.CloseReasonName ELSE 'Not Closed' END AS ClosureStatus,
    p.CommentCount,
    p.TotalVotes AS PostVotes,
    CASE 
        WHEN uvs.UpVotes > (SELECT AVG(UpVotes) FROM UserVoteStats) THEN 'Above Average Upvotes'
        ELSE 'Below Average Upvotes'
    END AS VotingPerformance
FROM UserVoteStats uvs
JOIN PostsWithVotes p ON p.TotalVotes > 0
LEFT JOIN PostHistoryDetails phd ON p.PostId = phd.PostId AND phd.PostHistoryTypeId IN (10, 11)
WHERE uvs.Rank <= 10 
ORDER BY uvs.UpVotes DESC, p.TotalVotes DESC;
