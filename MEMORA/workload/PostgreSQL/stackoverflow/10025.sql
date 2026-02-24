WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        AVG(P.AnswerCount) AS AvgAnswerCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    COALESCE(US.PostCount, 0) AS UserPostCount,
    COALESCE(US.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(US.UpVotes, 0) AS UserUpVotes,
    COALESCE(US.DownVotes, 0) AS UserDownVotes,
    COALESCE(PS.TotalPosts, 0) AS UserTotalPosts,
    COALESCE(PS.TotalScore, 0) AS UserTotalScore,
    COALESCE(PS.AvgViewCount, 0) AS UserAvgViewCount,
    COALESCE(PS.AvgAnswerCount, 0) AS UserAvgAnswerCount
FROM 
    Users U
LEFT JOIN 
    UserStats US ON U.Id = US.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
ORDER BY 
    U.Reputation DESC
LIMIT 100;