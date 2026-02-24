WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Tags) AS TagCount,
        SUM(P.ViewCount) AS ViewsFromTag
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')  
    GROUP BY 
        T.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(DISTINCT PH.Id) AS EditCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (52, 53) THEN 1 END) AS HotQuestionChanges
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        U.DisplayName AS Author,
        PS.TotalScore,
        PS.TotalViews,
        PH.EditCount,
        RANK() OVER (ORDER BY PS.TotalScore DESC, PS.TotalViews DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        UserPostStats PS ON P.OwnerUserId = PS.UserId
    LEFT JOIN 
        PostHistorySummary PH ON P.Id = PH.PostId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId IN (1, 2)  
)
SELECT 
    RP.Rank,
    RP.Title,
    RP.Author,
    RP.TotalScore,
    RP.TotalViews,
    PH.EditCount,
    TT.TagName,
    TT.TagCount,
    TT.ViewsFromTag
FROM 
    RankedPosts RP
LEFT JOIN 
    TopTags TT ON RP.Title LIKE CONCAT('%', TT.TagName, '%')  
LEFT JOIN 
    PostHistorySummary PH ON RP.Id = PH.PostId
WHERE 
    RP.Rank <= 20  
ORDER BY 
    RP.Rank;