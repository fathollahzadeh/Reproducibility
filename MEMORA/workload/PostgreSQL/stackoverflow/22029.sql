
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS PostRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  
    GROUP BY U.Id, U.DisplayName
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        U.DisplayName AS EditorName,
        PT.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS EditRank
    FROM PostHistory PH
    JOIN Users U ON PH.UserId = U.Id
    JOIN Posts P ON PH.PostId = P.Id
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    WHERE PHT.Name IN ('Post Closed', 'Post Reopened')
),
ClosedPostActivity AS (
    SELECT 
        CPH.PostId,
        CPH.EditorName,
        CPH.PostType,
        CASE 
            WHEN CPH.EditRank = 1 THEN 'Closed'
            WHEN CPH.EditRank > 1 THEN 'Reopened'
            ELSE 'Unchanged'
        END AS Status
    FROM ClosedPostHistory CPH
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalBounty,
    UA.TotalViews,
    COALESCE(CPA.Status, 'No Activity') AS PostStatus,
    COALESCE(CPA.PostType, 'N/A') AS PostType
FROM UserActivity UA
LEFT JOIN ClosedPostActivity CPA ON UA.UserId = (
    SELECT U.Id
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    JOIN ClosedPostHistory CPH ON P.Id = CPH.PostId
    LIMIT 1
)
WHERE UA.TotalPosts > 0
ORDER BY UA.TotalPosts DESC, UA.TotalComments DESC;
