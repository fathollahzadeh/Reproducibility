
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 6 THEN 1 ELSE 0 END), 0) AS CloseVotes
    FROM 
        Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TagStats AS (
    SELECT
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM
        Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
),
ClosedPosts AS (
    SELECT
        P.Id AS ClosedPostId,
        PH.UserId AS CloserUserId,
        PH.CreationDate AS CloseDate,
        PH.Comment AS CloseReason
    FROM
        Posts P
    JOIN PostHistory PH ON PH.PostId = P.Id AND PH.PostHistoryTypeId = 10
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(US.UpVotes, 0) AS TotalUpVotes,
    COALESCE(US.DownVotes, 0) AS TotalDownVotes,
    COALESCE(US.CloseVotes, 0) AS TotalCloseVotes,
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    TS.AverageScore,
    CP.ClosedPostId,
    CP.CloserUserId,
    CP.CloseDate,
    CP.CloseReason
FROM 
    Users U
LEFT JOIN UserVoteStats US ON U.Id = US.UserId
LEFT JOIN TagStats TS ON TS.PostCount > 0
LEFT JOIN ClosedPosts CP ON U.Id = CP.CloserUserId
WHERE 
    (COALESCE(US.UpVotes, 0) > 10 OR COALESCE(US.DownVotes, 0) < 5)
    AND (TS.AverageScore IS NOT NULL OR TS.PostCount IS NULL)
ORDER BY 
    TotalUpVotes DESC, TotalCloseVotes ASC
LIMIT 100;
