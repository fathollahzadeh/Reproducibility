
WITH UserActivity AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(P.Score) AS TotalScore,
           COUNT(DISTINCT C.Id) AS CommentCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE U.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY U.Id, U.DisplayName
),
ActiveUsers AS (
    SELECT UserId,
           DisplayName,
           QuestionCount,
           AnswerCount,
           TotalScore,
           CommentCount,
           RANK() OVER (ORDER BY QuestionCount DESC) AS QuestionRank,
           RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserActivity
)
SELECT A.DisplayName,
       A.QuestionCount,
       A.AnswerCount,
       A.TotalScore,
       A.CommentCount,
       COALESCE(CASE WHEN A.QuestionRank = 1 THEN 'Top Questioner' ELSE NULL END, 
                  CASE WHEN A.ScoreRank = 1 THEN 'Top Contributor' END) AS Achievement
FROM ActiveUsers A
LEFT JOIN Badges B ON A.UserId = B.UserId
WHERE (A.QuestionCount > 5 OR A.AnswerCount > 10)
    AND B.Id IS NULL
ORDER BY A.TotalScore DESC, A.QuestionCount DESC
LIMIT 20;
