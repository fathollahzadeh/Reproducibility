WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT COALESCE(A.Id, 0)) AS AnswerCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(B.Class) AS TotalBadges,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Posts A ON P.AcceptedAnswerId = A.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        *, 
        RANK() OVER (ORDER BY Reputation DESC, PostCount DESC, AnswerCount DESC, TotalBadges DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    PostCount, 
    AnswerCount, 
    CommentCount, 
    TotalBadges, 
    CloseCount, 
    ReopenCount, 
    Rank
FROM 
    RankedUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
