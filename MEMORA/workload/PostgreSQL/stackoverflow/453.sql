
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(COALESCE(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        PostCount,
        TotalViews,
        QuestionCount,
        AnswerCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS ClosedDate,
        c.Name AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ReasonRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    JOIN 
        CloseReasonTypes c ON c.Id = CAST(JSON_VALUE(ph.Comment, '$.closeReasonId') AS INTEGER)
    WHERE 
        ph.CreationDate IS NOT NULL
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalViews,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalScore,
    ARRAY_AGG(DISTINCT cp.Title) AS ClosedPostsTitles,
    COUNT(DISTINCT cp.PostId) AS TotalClosedPosts,
    COALESCE(AVG(CASE WHEN cp.ReasonRank = 1 THEN 1 ELSE 0 END), 0) AS ReopenedPostsCount
FROM 
    TopUsers tu
LEFT JOIN 
    ClosedPosts cp ON tu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
WHERE 
    tu.ScoreRank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.PostCount, tu.TotalViews, tu.QuestionCount, tu.AnswerCount, tu.TotalScore
ORDER BY 
    tu.TotalScore DESC;
