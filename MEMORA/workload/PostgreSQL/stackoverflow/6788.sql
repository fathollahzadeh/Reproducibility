
WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate, DisplayName, LastAccessDate
    FROM Users
    WHERE Reputation > 1000
),
PopularQuestions AS (
    SELECT P.Id AS PostId, P.Title, P.CreationDate, P.Score, P.ViewCount, COUNT(A.Id) AS AnswerCount, P.OwnerUserId
    FROM Posts P
    LEFT JOIN Posts A ON P.Id = A.ParentId
    WHERE P.PostTypeId = 1
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.OwnerUserId
    HAVING COUNT(A.Id) >= 5 AND P.Score >= 10
),
RecentEdits AS (
    SELECT PH.PostId, PH.UserId, PH.CreationDate, PH.Comment, U.DisplayName AS Editor
    FROM PostHistory PH
    JOIN Users U ON PH.UserId = U.Id
    WHERE PH.PostHistoryTypeId IN (4, 5)
    AND PH.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
)
SELECT 
    U.DisplayName AS UserName,
    P.Title AS QuestionTitle,
    P.Score AS QuestionScore,
    P.ViewCount AS QuestionViews,
    RE.Editor,
    RE.CreationDate AS EditDate,
    RE.Comment AS EditComment
FROM UserReputation U
JOIN PopularQuestions P ON U.Id = P.OwnerUserId
JOIN RecentEdits RE ON P.PostId = RE.PostId
ORDER BY P.Score DESC, RE.CreationDate DESC
LIMIT 10;
