
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.UserId, ph.PostHistoryTypeId
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        AcceptedAnswers,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM UserPostStats
),
PostEditFrequency AS (
    SELECT 
        phs.PostId,
        SUM(CASE WHEN phs.PostHistoryTypeId IN (4, 5) THEN 1 ELSE 0 END) AS EditCount,
        SUM(CASE WHEN phs.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM PostHistoryStats phs
    GROUP BY phs.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.QuestionCount,
    u.AnswerCount,
    u.AcceptedAnswers,
    u.AvgScore,
    COALESCE(pe.EditCount, 0) AS EditCount,
    COALESCE(pe.CloseCount, 0) AS CloseCount,
    v.UserRank AS Rank
FROM TopUsers u
LEFT JOIN PostEditFrequency pe ON u.UserId = pe.PostId
JOIN (
    SELECT 
        UserId,
        COUNT(*) AS UserRank
    FROM Votes v
    WHERE v.VoteTypeId IN (2, 3) 
    GROUP BY UserId
) v ON u.UserId = v.UserId
WHERE u.TotalPosts > 10
ORDER BY u.TotalPosts DESC, u.AvgScore DESC;
