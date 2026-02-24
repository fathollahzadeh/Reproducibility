
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN P.LastActivityDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentPosts
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
), 
PostVoteStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),
RecentPostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS TotalComments
    FROM Comments C
    WHERE C.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 week'
    GROUP BY C.PostId
),
PostHistoryInfo AS (
    SELECT 
        PH.PostId,
        PH.UserDisplayName,
        PH.CreationDate,
        PH.Comment
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11, 12) 
),
RankedUsers AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.TotalPosts,
        UPS.TotalAnswers,
        UPS.AcceptedAnswers,
        UPS.RecentPosts,
        PVS.TotalVotes,
        PVS.UpVotes,
        PVS.DownVotes,
        RANK() OVER (ORDER BY UPS.TotalPosts DESC) AS PostRank
    FROM UserPostStats UPS
    JOIN PostVoteStats PVS ON UPS.UserId = PVS.PostId
)

SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.TotalPosts,
    RU.TotalAnswers,
    RU.AcceptedAnswers,
    RU.RecentPosts,
    COALESCE(RC.TotalComments, 0) AS CommentsInLastWeek,
    COALESCE(PH.UserDisplayName, 'No History') AS LastActionUser,
    PH.CreationDate AS LastActionDate,
    PH.Comment AS LastActionComment
FROM RankedUsers RU
LEFT JOIN RecentPostComments RC ON RU.UserId = RC.PostId
LEFT JOIN PostHistoryInfo PH ON RU.UserId = PH.PostId
WHERE RU.RecentPosts > 0
ORDER BY RU.PostRank, RU.UserId;
