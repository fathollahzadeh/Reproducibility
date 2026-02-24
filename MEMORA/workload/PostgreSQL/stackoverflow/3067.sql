
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostActivitySummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(PS.TotalComments, 0) AS TotalComments
    FROM Posts P
    LEFT JOIN (
        SELECT 
            A.ParentId,
            COUNT(*) AS TotalAnswers,
            COUNT(DISTINCT C.Id) AS TotalComments
        FROM Posts A
        LEFT JOIN Comments C ON A.Id = C.PostId
        WHERE A.PostTypeId = 2
        GROUP BY A.ParentId
    ) PS ON P.Id = PS.ParentId
    WHERE P.PostTypeId = 1
),
ClosedPostSummary AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseCount,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
)
SELECT 
    UPS.DisplayName AS UserName,
    UPS.TotalUpvotes,
    UPS.TotalDownvotes,
    PAS.PostId,
    PAS.Title AS PostTitle,
    PAS.ViewCount,
    PAS.TotalAnswers,
    PAS.TotalComments,
    CPS.CloseCount,
    CPS.LastClosedDate
FROM UserVoteSummary UPS
INNER JOIN Posts P ON UPS.UserId = P.OwnerUserId
INNER JOIN PostActivitySummary PAS ON P.Id = PAS.PostId
LEFT JOIN ClosedPostSummary CPS ON PAS.PostId = CPS.PostId
WHERE UPS.TotalUpvotes > UPS.TotalDownvotes
ORDER BY PAS.ViewCount DESC, UPS.TotalUpvotes DESC;
