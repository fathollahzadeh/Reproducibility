WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE(CLOSED_REASON.CloseReasonName, 'Active') AS PostStatus
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PH.PostId,
            CR.Name AS CloseReasonName
        FROM 
            PostHistory PH
        JOIN 
            CloseReasonTypes CR ON PH.Comment::int = CR.Id
        WHERE 
            PH.PostHistoryTypeId IN (10, 11)  
        ORDER BY 
            PH.CreationDate DESC
    ) CLOSED_REASON ON P.Id = CLOSED_REASON.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalBounty,
    pi.PostId,
    pi.Title,
    pi.CreationDate,
    pi.Score,
    pi.ViewCount,
    pi.AnswerCount,
    pi.CommentCount,
    pi.PostStatus,
    ROW_NUMBER() OVER (PARTITION BY us.UserId ORDER BY pi.CreationDate DESC) AS PostRank
FROM 
    UserStatistics us
JOIN 
    PostInfo pi ON us.UserId = pi.PostId 
WHERE 
    us.Reputation > (SELECT AVG(Reputation) FROM Users)  
ORDER BY 
    us.Reputation DESC, 
    pi.CreationDate DESC;