WITH RecursivePostHistory AS (
    SELECT
        ph.Id AS PostHistoryId,
        p.Id AS PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM
        PostHistory ph
        JOIN Posts p ON ph.PostId = p.Id
    WHERE
        ph.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),
PostWithAcceptedAnswers AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        pa.Title AS AcceptedAnswerTitle,
        pa.Score AS AcceptedAnswerScore
    FROM
        Posts p
    LEFT JOIN Posts pa ON p.AcceptedAnswerId = pa.Id
    WHERE
        p.PostTypeId = 1 
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COALESCE(b.Count, 0) AS BadgeCount
    FROM
        Users u
    LEFT JOIN (
        SELECT
            UserId,
            COUNT(*) AS Count
        FROM
            Badges
        GROUP BY
            UserId
    ) b ON u.Id = b.UserId
)
SELECT 
    p.PostId,
    p.Title AS QuestionTitle,
    p.Score AS QuestionScore,
    p.ViewCount AS QuestionViews,
    COALESCE(p.AcceptedAnswerTitle, 'No accepted answer') AS AcceptedAnswerTitle,
    COALESCE(p.AcceptedAnswerScore, 0) AS AcceptedAnswerScore,
    u.DisplayName AS UserName,
    u.Reputation AS UserReputation,
    u.Views AS UserViews,
    CASE
        WHEN u.Reputation > 1000 THEN 'High reputation'
        WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium reputation'
        ELSE 'Low reputation'
    END AS ReputationCategory,
    COUNT(ph.PostHistoryId) AS EditCount
FROM 
    PostWithAcceptedAnswers p
JOIN 
    UserReputation u ON p.PostId IN (
        SELECT PostId FROM Votes WHERE UserId = u.UserId
    )
LEFT JOIN 
    RecursivePostHistory ph ON p.PostId = ph.PostId
GROUP BY 
    p.PostId, p.Title, p.Score, p.ViewCount, p.AcceptedAnswerTitle, p.AcceptedAnswerScore, 
    u.DisplayName, u.Reputation, u.Views
HAVING 
    COUNT(ph.PostHistoryId) > 1
ORDER BY 
    p.Score DESC, QuestionViews DESC;