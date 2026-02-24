WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    PS.UserId,
    PS.DisplayName,
    PS.PostCount,
    PS.QuestionCount,
    PS.AnswerCount,
    PS.TotalBounty,
    PS.TotalUpVotes,
    PS.TotalDownVotes,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    COALESCE(B.HighestBadgeClass, 0) AS HighestBadgeClass
FROM 
    UserPostStats PS
LEFT JOIN 
    UserBadges B ON PS.UserId = B.UserId
ORDER BY 
    PS.TotalUpVotes DESC, PS.PostCount DESC
LIMIT 50;
