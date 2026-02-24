
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(PHT.Name, '; ') AS HistoryTypeNames
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE PH.PostHistoryTypeId IN (4, 5, 6, 10, 12) 
    GROUP BY PH.PostId
),
TopUsers AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.TotalPosts,
        UPS.Questions,
        UPS.Answers,
        UPS.TotalViews,
        UPS.AvgScore,
        ROW_NUMBER() OVER (ORDER BY UPS.TotalPosts DESC, UPS.AvgScore DESC) AS Rank
    FROM UserPostStats UPS
    WHERE UPS.TotalPosts > 0
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.Questions,
    TU.Answers,
    TU.TotalViews,
    TU.AvgScore,
    PHS.EditCount,
    PHS.LastEditDate,
    PHS.HistoryTypeNames
FROM TopUsers TU
LEFT JOIN PostHistoryStats PHS ON TU.UserId IN (SELECT OwnerUserId FROM Posts WHERE OwnerUserId IS NOT NULL) 
WHERE TU.Rank <= 10 
AND COALESCE(PHS.EditCount, 0) > 0
ORDER BY TU.TotalPosts DESC, TU.AvgScore DESC;
