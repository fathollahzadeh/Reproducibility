
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId IN (6, 7) THEN 1 END) AS CloseReopenVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
TagUsage AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY T.TagName
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.ViewCount
),
PostPerformance AS (
    SELECT 
        PA.PostId,
        PA.Title,
        PA.ViewCount,
        PA.CommentCount,
        PA.NetVotes,
        TU.PostCount AS TagPostCount
    FROM PostActivity PA
    JOIN TagUsage TU ON PA.Title LIKE CONCAT('%', TU.TagName, '%')
)
SELECT 
    UPS.DisplayName,
    UPS.UpVotes,
    UPS.DownVotes,
    UPS.CloseReopenVotes,
    PP.Title,
    PP.ViewCount,
    PP.CommentCount,
    PP.NetVotes,
    PP.TagPostCount
FROM UserVoteStats UPS
JOIN PostPerformance PP ON UPS.UserId = PP.PostId
ORDER BY UPS.UpVotes DESC, PP.ViewCount DESC
LIMIT 100;
