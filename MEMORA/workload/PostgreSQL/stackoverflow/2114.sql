
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        COUNT(*) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
QuestionAnswerStatistics AS (
    SELECT 
        P.Id AS QuestionId,
        COUNT(A.Id) AS AnswerCount,
        COALESCE(SUM(A.Score), 0) AS TotalAnswerScore
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id
),
PostHistoryAnalytics AS (
    SELECT 
        PH.PostId,
        P.Title,
        P.CreationDate,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        PH.PostId, P.Title, P.CreationDate
),
TopUsers AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
)

SELECT 
    UVC.UserId,
    UVC.DisplayName AS UserName,
    UVC.UpvoteCount,
    UVC.DownvoteCount,
    UVC.TotalVotes,
    Q.QuestionId,
    Q.AnswerCount,
    Q.TotalAnswerScore,
    PH.EditCount,
    PH.LastEditDate,
    TU.Rank AS UserRank
FROM 
    UserVoteCounts UVC
JOIN 
    QuestionAnswerStatistics Q ON Q.QuestionId IN (
        SELECT P.Id FROM Posts P WHERE P.OwnerUserId = UVC.UserId AND P.PostTypeId = 1
    )
LEFT JOIN 
    PostHistoryAnalytics PH ON PH.PostId IN (
        SELECT P.Id FROM Posts P WHERE P.OwnerUserId = UVC.UserId
    )
JOIN 
    TopUsers TU ON TU.DisplayName = UVC.DisplayName
WHERE 
    (UVC.UpvoteCount - UVC.DownvoteCount) > 10
ORDER BY 
    UVC.TotalVotes DESC, 
    UVC.UserId
FETCH FIRST 50 ROWS ONLY;
