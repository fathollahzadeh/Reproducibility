
WITH UserVotingStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        COUNT(CASE WHEN V.VoteTypeId IN (1, 6, 7) THEN 1 END) AS ActionableVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(PH.CreationDate, DATE '1970-01-01') AS MostRecentEdit,
        COUNT(A.Id) AS AnswerCount,
        RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6)
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, PH.CreationDate
    HAVING 
        COUNT(A.Id) > 0
),
EnhancedPostStats AS (
    SELECT 
        TQ.PostId,
        TQ.Title,
        TQ.CreationDate,
        TQ.Score,
        TQ.MostRecentEdit,
        TQ.AnswerCount,
        CASE 
            WHEN TQ.ScoreRank <= 10 THEN 'Top'
            WHEN TQ.ScoreRank BETWEEN 11 AND 20 THEN 'Mid'
            ELSE 'Low' 
        END AS ScoreCategory
    FROM 
        TopQuestions TQ
)
SELECT 
    EPS.Title,
    EPS.Score,
    EPS.AnswerCount,
    UVS.DisplayName,
    UVS.UpvoteCount,
    UVS.DownvoteCount,
    EPS.ScoreCategory,
    COALESCE(EPS.MostRecentEdit, TIMESTAMP '1970-01-01 00:00:00') AS MostRecentEdit
FROM 
    EnhancedPostStats EPS
JOIN 
    UserVotingStats UVS ON EPS.PostId IN (
        SELECT 
            PostId 
        FROM 
            Votes 
        WHERE 
            UserId = UVS.UserId
    )
WHERE 
    UVS.ActionableVotes >= 1
ORDER BY 
    EPS.Score DESC, UVS.UpvoteCount DESC;
