WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        SUM(CASE WHEN PHT.Name = 'Edit Body' THEN 1 ELSE 0 END) AS BodyEdits,
        SUM(CASE WHEN PHT.Name = 'Edit Title' THEN 1 ELSE 0 END) AS TitleEdits
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.PostCount,
    UPS.TotalScore,
    UPS.TotalViews,
    UPS.QuestionCount,
    UPS.AnswerCount,
    PHS.EditCount,
    PHS.BodyEdits,
    PHS.TitleEdits
FROM 
    UserPostStats UPS
LEFT JOIN 
    PostHistoryStats PHS ON UPS.UserId = PHS.PostId
ORDER BY 
    UPS.TotalScore DESC
LIMIT 100;