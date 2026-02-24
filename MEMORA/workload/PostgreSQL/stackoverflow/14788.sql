WITH UserPostStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT
        PH.UserId,
        COUNT(PH.Id) AS TotalEdits,
        SUM(CASE WHEN PHT.Name = 'Edit Title' THEN 1 ELSE 0 END) AS TotalTitleEdits,
        SUM(CASE WHEN PHT.Name = 'Edit Body' THEN 1 ELSE 0 END) AS TotalBodyEdits,
        SUM(CASE WHEN PHT.Name = 'Edit Tags' THEN 1 ELSE 0 END) AS TotalTagEdits
    FROM
        PostHistory PH
    JOIN
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY
        PH.UserId
),
CombinedStats AS (
    SELECT
        UPS.UserId,
        UPS.DisplayName,
        UPS.TotalPosts,
        UPS.TotalQuestions,
        UPS.TotalAnswers,
        UPS.TotalTagWikis,
        UPS.TotalScore,
        UPS.AvgViewCount,
        PHS.TotalEdits,
        PHS.TotalTitleEdits,
        PHS.TotalBodyEdits,
        PHS.TotalTagEdits
    FROM
        UserPostStats UPS
    LEFT JOIN
        PostHistoryStats PHS ON UPS.UserId = PHS.UserId
)
SELECT
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalTagWikis,
    TotalScore,
    AvgViewCount,
    COALESCE(TotalEdits, 0) AS TotalEdits,
    COALESCE(TotalTitleEdits, 0) AS TotalTitleEdits,
    COALESCE(TotalBodyEdits, 0) AS TotalBodyEdits,
    COALESCE(TotalTagEdits, 0) AS TotalTagEdits
FROM
    CombinedStats
ORDER BY
    TotalScore DESC;