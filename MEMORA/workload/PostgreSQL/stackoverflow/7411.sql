WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostsCount,
        AVG(U.Reputation) AS AvgReputation
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.CreationDate,
        P.LastActivityDate,
        T.TagName
    FROM Posts P
    LEFT JOIN Tags T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
RecentEdits AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY PH.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    U.PostsCount,
    U.AvgReputation,
    P.PostId,
    P.Title,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount,
    P.CreationDate AS PostCreationDate,
    P.LastActivityDate AS PostLastActivityDate,
    E.EditCount,
    E.LastEditDate
FROM UserVoteStats U
JOIN PostStats P ON U.PostsCount > 5
LEFT JOIN RecentEdits E ON P.PostId = E.PostId
ORDER BY U.UpVotes DESC, P.Score DESC
LIMIT 100;