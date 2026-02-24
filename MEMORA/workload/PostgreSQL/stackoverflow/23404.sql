
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
QuestionStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        COUNT(A.Id) AS AnswerCount,
        COUNT(C.Id) AS CommentCount,
        MAX(CASE 
            WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate 
            ELSE NULL 
        END) AS ClosedDate,
        MAX(CASE 
            WHEN PH.PostHistoryTypeId = 11 THEN PH.CreationDate 
            ELSE NULL 
        END) AS ReopenedDate,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM Posts P
    LEFT JOIN Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.PostTypeId = 1
    GROUP BY P.Id, P.Score
),
FilteredQuestions AS (
    SELECT 
        QS.PostId,
        QS.Score,
        QS.AnswerCount,
        QS.CommentCount,
        US.DisplayName AS TopUser,
        US.Reputation AS UserReputation
    FROM QuestionStatistics QS
    JOIN UserStatistics US ON US.UserId = (
        SELECT U.Id 
        FROM Users U 
        WHERE U.Id IN (
            SELECT DISTINCT P.OwnerUserId 
            FROM Posts P 
            WHERE P.Id = QS.PostId
        )
        ORDER BY U.Reputation DESC
        LIMIT 1
    )
    WHERE QS.ClosedDate IS NULL
      AND QS.AnswerCount > 0 
      AND QS.Score >= (
          SELECT AVG(Score) 
          FROM Posts 
          WHERE PostTypeId = 1
      )
)
SELECT 
    FQ.PostId,
    FQ.TopUser,
    FQ.UserReputation,
    FQ.AnswerCount,
    FQ.CommentCount,
    GREATEST(FQ.UserReputation / NULLIF(FQ.AnswerCount, 0), 1) AS ReputationPerAnswer,
    CASE 
        WHEN FQ.UserReputation > 1000 THEN 'Experienced'
        WHEN FQ.UserReputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Beginner'
    END AS UserLevel
FROM FilteredQuestions FQ
ORDER BY FQ.UserReputation DESC, FQ.Score DESC
LIMIT 10 OFFSET 0;
