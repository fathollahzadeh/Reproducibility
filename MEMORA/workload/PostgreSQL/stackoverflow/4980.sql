
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(PT.Id) AS PostCount
    FROM Tags T 
    JOIN Posts PT ON PT.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    HAVING COUNT(PT.Id) > 5
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN PH.PostHistoryTypeId = 11 THEN PH.CreationDate END) AS LastReopenedDate
    FROM PostHistory PH
    GROUP BY PH.PostId
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        PH.LastClosedDate,
        PH.LastReopenedDate,
        COALESCE(UP.TotalPosts, 0) AS UserTotalPosts,
        COALESCE(UP.TotalAnswers, 0) AS UserTotalAnswers,
        COALESCE(UP.UpVotesCount, 0) AS UserUpVotes,
        COALESCE(UP.DownVotesCount, 0) AS UserDownVotes
    FROM Posts P
    LEFT JOIN UserActivity UP ON P.OwnerUserId = UP.UserId
    LEFT JOIN RecentPostHistory PH ON P.Id = PH.PostId
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.ViewCount,
    PD.LastClosedDate,
    PD.LastReopenedDate,
    T.TagName,
    COUNT(CASE WHEN CV.UserId IS NOT NULL THEN 1 END) AS CountOfUsersCommented,
    ROW_NUMBER() OVER (PARTITION BY PD.PostId ORDER BY PD.CreationDate DESC) AS RowNum
FROM PostDetails PD
JOIN PostLinks PL ON PD.PostId = PL.PostId
JOIN Tags T ON PL.RelatedPostId = T.Id
LEFT JOIN Comments CV ON PD.PostId = CV.PostId
WHERE (PD.LastClosedDate IS NULL OR PD.LastReopenedDate > PD.LastClosedDate)
GROUP BY PD.PostId, PD.Title, PD.CreationDate, PD.ViewCount, PD.LastClosedDate, PD.LastReopenedDate, T.TagName
HAVING COUNT(CASE WHEN CV.UserId IS NOT NULL THEN 1 END) > 0
ORDER BY PD.CreationDate DESC, CountOfUsersCommented DESC;
