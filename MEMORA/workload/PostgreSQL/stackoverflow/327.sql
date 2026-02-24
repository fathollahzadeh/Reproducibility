
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN P.PostTypeId IN (1, 2) THEN 1 ELSE 0 END), 0) AS PostCount,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Ranking
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
QuestionDetails AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        COUNT(A.Id) AS AnswerCount,
        COALESCE(SUM(C.COMMENT_COUNT), 0) AS TotalComments,
        COALESCE(AVG(V.VOTE_COUNT), 0) AS AverageVotes,
        MAX(P.CreationDate) AS LastActivity
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS COMMENT_COUNT 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) AS C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VOTE_COUNT 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) AS V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 AND
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month')
    GROUP BY 
        P.Id, P.Title
),
FinalSummary AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.PostCount,
        UA.CommentCount,
        UA.NetVotes,
        UA.Reputation,
        QD.QuestionId,
        QD.Title,
        QD.AnswerCount,
        QD.TotalComments,
        QD.AverageVotes,
        QD.LastActivity
    FROM 
        UserActivity UA
    JOIN 
        QuestionDetails QD ON UA.UserId = (
            SELECT OwnerUserId 
            FROM Posts 
            WHERE Id = QD.QuestionId 
            LIMIT 1
        )
)
SELECT 
    FS.DisplayName,
    FS.PostCount,
    FS.CommentCount,
    FS.NetVotes,
    FS.Reputation,
    FS.QuestionId,
    FS.Title,
    FS.AnswerCount,
    FS.TotalComments,
    FS.AverageVotes,
    FS.LastActivity,
    RANK() OVER (ORDER BY FS.Reputation DESC) AS ReputationRank
FROM 
    FinalSummary FS
ORDER BY 
    FS.Reputation DESC, FS.NetVotes DESC
LIMIT 10;
