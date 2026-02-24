WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT
        ph.UserId,
        COUNT(ph.Id) AS EditCount,
        COUNT(DISTINCT ph.PostId) AS PostsEdited
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6, 24)  
    GROUP BY
        ph.UserId
),
CombinedStats AS (
    SELECT
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.PositiveScorePosts,
        ups.AvgViewCount,
        ups.AvgScore,
        COALESCE(phe.EditCount, 0) AS EditCount,
        COALESCE(phe.PostsEdited, 0) AS PostsEdited
    FROM
        UserPostStats ups
    LEFT JOIN
        PostHistoryStats phe ON ups.UserId = phe.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    PositiveScorePosts,
    AvgViewCount,
    AvgScore,
    EditCount,
    PostsEdited
FROM 
    CombinedStats
ORDER BY 
    PostCount DESC;