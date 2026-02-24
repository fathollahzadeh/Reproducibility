WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotesCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotesCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId IN (2, 3)) AS TotalVotes,
        RANK() OVER (ORDER BY COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) DESC) AS UpVoteRank,
        RANK() OVER (ORDER BY COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) DESC) AS DownVoteRank
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),

PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN LATERAL (SELECT * FROM unnest(string_to_array(p.Tags, ',')) AS t(TagName)) t ON TRUE
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.ViewCount, p.AcceptedAnswerId
),

TopPosts AS (
    SELECT 
        pd.*,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN pd.AcceptedAnswerId = -1 THEN 'No Accepted Answer'
            ELSE 'Has Accepted Answer'
        END AS AcceptedAnswerStatus,
        ROW_NUMBER() OVER (ORDER BY pd.ViewCount DESC) AS PopularityRank
    FROM PostDetails pd
    JOIN Users u ON pd.OwnerUserId = u.Id
    WHERE pd.CommentCount > 0
),

PostVoteAnalysis AS (
    SELECT 
        tp.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END), 0) AS CloseVotes,
        MAX(u.DisplayName) AS TopVoter,
        COUNT(v.Id) AS VoteRecordsCount
    FROM TopPosts tp
    LEFT JOIN Votes v ON tp.PostId = v.PostId
    LEFT JOIN Users u ON v.UserId = u.Id
    GROUP BY tp.PostId
)

SELECT 
    t.Title,
    t.OwnerDisplayName,
    t.AcceptedAnswerStatus,
    tp.TotalUpVotes,
    tp.TotalDownVotes,
    tp.VoteRecordsCount,
    u.DisplayName AS VoterDisplayName,
    u.UpVotesCount,
    u.DownVotesCount,
    CASE 
        WHEN tp.CloseVotes IS NULL THEN 'No Close Votes'
        ELSE 'Closed ' || tp.CloseVotes || ' Times'
    END AS CloseVoteStatus,
    CASE 
        WHEN (tp.CloseVotes > 0 AND tp.TotalUpVotes < tp.TotalDownVotes) THEN 'Suspicious Post'
        ELSE 'Normal Post'
    END AS PostStatus,
    CASE 
        WHEN t.PopularityRank <= 10 THEN 'Trending!'
        ELSE 'Regular Post'
    END AS TrendingStatus
FROM PostVoteAnalysis tp
JOIN UserVoteStats u ON u.UpVoteRank <= 10 OR u.DownVoteRank <= 10
JOIN TopPosts t ON t.PostId = tp.PostId
WHERE tp.TotalUpVotes - tp.TotalDownVotes > 0
ORDER BY t.ViewCount DESC
LIMIT 50;