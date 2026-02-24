
WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END), 0) AS WikiCount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        RANK() OVER (ORDER BY COALESCE(SUM(p.Score), 0) DESC) AS ScoreRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        WikiCount,
        TotalViews,
        TotalScore,
        ScoreRank
    FROM UserPostStats
    WHERE ScoreRank <= 10
),
PostHistorySummary AS (
    SELECT
        post.Id AS PostId,
        pt.Name AS PostType,
        COUNT(ph.PostId) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM Posts post
    JOIN PostHistory ph ON post.Id = ph.PostId
    JOIN PostHistoryTypes pt ON pt.Id = ph.PostHistoryTypeId
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY post.Id, pt.Name
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(ph.EditCount, 0) AS EditCount,
        ph.LastEditDate
    FROM Posts p
    LEFT JOIN PostHistorySummary ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
)

SELECT 
    u.DisplayName AS UserDisplayName,
    u.QuestionCount,
    u.AnswerCount,
    u.WikiCount,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.EditCount,
    r.LastEditDate,
    CASE 
        WHEN r.EditCount > 0 THEN 'Edited'
        ELSE 'Unedited'
    END AS EditStatus
FROM TopUsers u
JOIN RecentPosts r ON u.UserId = r.OwnerUserId
ORDER BY u.ScoreRank, u.TotalScore DESC, r.CreationDate DESC;
