
WITH UserVoteStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        COUNT(v.Id) AS TotalVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(v.Id) DESC) AS UserVoteRank
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
), PostScoreHistory AS (
    SELECT 
        p.Id AS PostId, 
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 ELSE 0 END) AS DeleteCount,
        MAX(p.Score) AS MaxScore,
        MIN(p.Score) AS MinScore,
        AVG(p.Score) AS AvgScore
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id
), UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(ph.CloseCount, 0)) AS TotalPostsClosed,
        SUM(COALESCE(ph.DeleteCount, 0)) AS TotalPostsDeleted,
        MAX(ph.MaxScore) AS BestPostScore,
        MIN(ph.MinScore) AS WorstPostScore,
        AVG(ph.AvgScore) AS AveragePostScore
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostScoreHistory ph ON p.Id = ph.PostId
    GROUP BY u.Id
), RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        us.PostCount,
        us.TotalPostsClosed,
        us.TotalPostsDeleted,
        us.BestPostScore,
        us.WorstPostScore,
        us.AveragePostScore,
        RANK() OVER (ORDER BY us.AveragePostScore DESC, us.PostCount DESC) AS OverallRank
    FROM UserPostStatistics us
    JOIN Users u ON us.UserId = u.Id 
)
SELECT 
    r.UserId,
    r.DisplayName,
    r.PostCount,
    r.TotalPostsClosed,
    r.TotalPostsDeleted,
    r.BestPostScore,
    r.WorstPostScore,
    r.AveragePostScore,
    uv.UpvoteCount,
    uv.DownvoteCount,
    uv.TotalVotes,
    CASE 
        WHEN uv.TotalVotes = 0 THEN 'No Votes'
        WHEN uv.UpvoteCount > uv.DownvoteCount THEN 'Positive Feedback'
        WHEN uv.UpvoteCount < uv.DownvoteCount THEN 'Negative Feedback'
        ELSE 'Neutral Feedback'
    END AS VoteFeedback,
    CASE 
        WHEN r.BestPostScore IS NULL THEN NULL
        ELSE COALESCE(r.AveragePostScore / r.BestPostScore, 0) * 100 || '%' 
    END AS AverageScorePercentage
FROM RankedUsers r
LEFT JOIN UserVoteStatistics uv ON r.UserId = uv.UserId
WHERE r.OverallRank <= 10
ORDER BY r.OverallRank;
