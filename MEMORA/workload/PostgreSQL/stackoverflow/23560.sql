
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        ROW_NUMBER() OVER (PARTITION BY Id ORDER BY CreationDate DESC) AS Rank
    FROM 
        Users
),
QuestionActivity AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.CreationDate,
        COALESCE(UP.VoteCount, 0) AS UpVoteCount,
        COALESCE(DOWN.VoteCount, 0) AS DownVoteCount,
        COUNT(C.ID) AS CommentCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            PostId
    ) UP ON P.Id = UP.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 3 
        GROUP BY 
            PostId
    ) DOWN ON P.Id = DOWN.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON PH.PostId = P.Id AND PH.PostHistoryTypeId IN (4, 5) 
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, UP.VoteCount, DOWN.VoteCount
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.Reputation,
        LEAD(UR.Reputation) OVER (ORDER BY UR.Reputation DESC) AS NextReputation,
        LAG(UR.Reputation) OVER (ORDER BY UR.Reputation DESC) AS PrevReputation
    FROM 
        UserReputation UR
    WHERE 
        UR.Rank = 1
),
Validation AS (
    SELECT 
        U.UserId,
        CASE 
            WHEN U.Reputation IS NULL OR U.Reputation <= 0 THEN 0 
            ELSE 1 
        END AS IsValid
    FROM 
        TopUsers U
),
FinalResults AS (
    SELECT 
        QA.QuestionId,
        QA.Title,
        QA.UpVoteCount,
        QA.DownVoteCount,
        QA.CommentCount,
        QA.LastEditDate,
        V.IsValid
    FROM 
        QuestionActivity QA
    INNER JOIN 
        Validation V ON V.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = QA.QuestionId)
    WHERE 
        V.IsValid = 1 
        AND QA.UpVoteCount - QA.DownVoteCount >= 5
)
SELECT 
    FR.QuestionId,
    FR.Title,
    FR.UpVoteCount,
    FR.CommentCount,
    FR.LastEditDate,
    COUNT(DISTINCT B.Id) AS BadgeCount
FROM 
    FinalResults FR
LEFT JOIN 
    Badges B ON B.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = FR.QuestionId) 
             AND B.Class = 1 
GROUP BY 
    FR.QuestionId, FR.Title, FR.UpVoteCount, FR.CommentCount, FR.LastEditDate
ORDER BY 
    FR.UpVoteCount DESC, FR.CommentCount DESC;
