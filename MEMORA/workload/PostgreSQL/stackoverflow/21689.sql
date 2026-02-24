
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
),
TopQuestions AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(A.Id) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId, P.CreationDate, P.Score, P.ViewCount
),
RecentEdits AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate AS EditDate,
        PH.PostHistoryTypeId,
        STRING_AGG(CONCAT(PH.UserDisplayName, ': ', PH.Comment), '; ') AS EditComments
    FROM 
        PostHistory PH
    JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId, PH.UserId, PH.CreationDate, PH.PostHistoryTypeId
),
VoteStatistics AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    TQ.QuestionId,
    TQ.Title,
    U.DisplayName AS OwnerDisplayName,
    TQ.CreationDate,
    TQ.Score,
    TQ.ViewCount,
    COALESCE(RE.EditComments, 'No Edits') AS RecentEdits,
    COALESCE(VS.UpVotes, 0) AS TotalUpVotes,
    COALESCE(VS.DownVotes, 0) AS TotalDownVotes,
    R.Rank AS TopUserRank
FROM 
    TopQuestions TQ
JOIN 
    Users U ON TQ.OwnerUserId = U.Id
LEFT JOIN 
    RecentEdits RE ON TQ.QuestionId = RE.PostId
LEFT JOIN 
    VoteStatistics VS ON TQ.QuestionId = VS.PostId
LEFT JOIN 
    UserReputation R ON U.Id = R.UserId
WHERE 
    TQ.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
    AND TQ.ViewCount > 100 
ORDER BY 
    TQ.Score DESC,
    TQ.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
