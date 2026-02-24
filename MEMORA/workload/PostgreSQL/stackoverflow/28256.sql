WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS Author,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  
)

SELECT 
    RP.Tags,
    COUNT(RP.PostId) AS TotalQuestions,
    AVG(RP.Score) AS AvgScore,
    MAX(RP.ViewCount) AS MaxViews,
    MIN(RP.CreationDate) AS FirstQuestionDate,
    STRING_AGG(DISTINCT RP.Author, ', ') AS Authors,
    STRING_AGG(DISTINCT RP.Title, '; ') AS QuestionTitles
FROM 
    RankedPosts RP
WHERE 
    RP.Rank <= 5  
GROUP BY 
    RP.Tags
ORDER BY 
    TotalQuestions DESC, AvgScore DESC;