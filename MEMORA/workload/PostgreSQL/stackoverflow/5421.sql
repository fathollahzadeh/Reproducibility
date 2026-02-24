WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.UserId = U.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS BadgeCount
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
), PostStats AS (
    SELECT 
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(*) AS TotalPosts,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId, P.PostTypeId
), CombinedStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.Views,
        US.UpVotes,
        US.DownVotes,
        US.PostCount,
        US.CommentCount,
        US.BadgeCount,
        PS.PostTypeId,
        PS.TotalPosts,
        PS.AvgScore,
        PS.TotalViews,
        PS.TotalAnswers
    FROM 
        UserStats US
    LEFT JOIN 
        PostStats PS ON US.UserId = PS.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    Views,
    UpVotes,
    DownVotes,
    PostCount,
    CommentCount,
    BadgeCount,
    PostTypeId,
    TotalPosts,
    AvgScore,
    TotalViews,
    TotalAnswers
FROM 
    CombinedStats
WHERE 
    TotalPosts > 5
ORDER BY 
    Reputation DESC, TotalViews DESC
LIMIT 100;
