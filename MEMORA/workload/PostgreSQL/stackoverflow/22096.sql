WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS VoteBalance
    FROM Users AS u
    LEFT JOIN Votes AS v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(pc.TotalComments, 0) AS TotalComments,
        COALESCE(pl.LinkCount, 0) AS TotalLinks
    FROM Posts AS p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TotalComments
        FROM Comments
        GROUP BY PostId
    ) AS pc ON p.Id = pc.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS LinkCount
        FROM PostLinks
        GROUP BY PostId
    ) AS pl ON p.Id = pl.PostId
),
TopPosts AS (
    SELECT 
        ps.*,
        ROW_NUMBER() OVER (PARTITION BY ps.PostId ORDER BY ps.Score DESC) AS Rnk
    FROM PostStatistics AS ps
    WHERE ps.Score > 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.Text
    FROM PostHistory AS ph
    WHERE ph.PostHistoryTypeId = 10 
)
SELECT 
    up.UserId,
    up.DisplayName,
    COALESCE(tp.Title, 'No Title') AS PostTitle,
    COALESCE(tp.Score, 0) AS PostScore,
    tp.TotalComments,
    tp.TotalLinks,
    COUNT(DISTINCT cp.PostId) AS ClosedPostsCount,
    SUM(tp.ViewCount) AS AggregateViewCount,
    STRING_AGG(DISTINCT cp.Comment, '; ') AS CloseReasonComments,
    ARRAY_AGG(DISTINCT CASE WHEN up.UpVotes IS NOT NULL THEN up.UpVotes ELSE 0 END) AS UpVotesArray,
    ARRAY_AGG(DISTINCT CASE WHEN up.DownVotes IS NOT NULL THEN up.DownVotes ELSE 0 END) AS DownVotesArray,
    MAX(CASE WHEN up.VoteBalance > 0 THEN up.VoteBalance ELSE 0 END) AS PositiveVoteBalance
FROM UserVoteStats AS up
FULL OUTER JOIN TopPosts AS tp ON tp.PostId = up.UserId
LEFT JOIN ClosedPosts AS cp ON cp.UserId = up.UserId
GROUP BY up.UserId, up.DisplayName, tp.Title, tp.Score, tp.TotalComments, tp.TotalLinks
HAVING COUNT(cp.PostId) > 0 OR SUM(tp.ViewCount) > 1000
ORDER BY up.DisplayName ASC, PostScore DESC;