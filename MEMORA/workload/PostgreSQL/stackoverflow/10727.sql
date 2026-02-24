WITH PostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(p.ViewCount) AS TotalViewCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.CreationDate - u.CreationDate) AS AvgPostAge
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
)

SELECT 
    ps.UserId,
    ps.DisplayName,
    ps.PostCount,
    ps.QuestionsCount,
    ps.AnswersCount,
    ps.TotalViewCount,
    ps.TotalScore,
    ps.AvgPostAge
FROM 
    PostStats ps
ORDER BY 
    ps.TotalScore DESC, ps.PostCount DESC;