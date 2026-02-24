WITH QuestionStats AS (
    SELECT
        p.Id AS QuestionId,
        p.Score AS QuestionScore,
        p.ViewCount AS QuestionViews,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(AVG(a.Score), 0) AS AverageAnswerScore,
        COALESCE(AVG(a.ViewCount), 0) AS AverageAnswerViews
    FROM
        Posts p
    LEFT JOIN
        Posts a ON p.Id = a.ParentId
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        p.Id, p.Score, p.ViewCount
)

SELECT
    Q.QuestionId,
    Q.QuestionScore,
    Q.QuestionViews,
    Q.AnswerCount,
    Q.AverageAnswerScore,
    Q.AverageAnswerViews
FROM
    QuestionStats Q
ORDER BY
    Q.QuestionId;