
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS Wikis,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COALESCE(AVG(V.BountyAmount), 0) AS AverageBounty,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        Questions,
        Answers,
        Wikis,
        TotalBounties,
        AverageBounty,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStatistics
),
UserComments AS (
    SELECT 
        C.UserId,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT C.PostId) AS UniquePostComments
    FROM 
        Comments C
    GROUP BY 
        C.UserId
)

SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.Questions,
    TU.Answers,
    TU.Wikis,
    TU.TotalBounties,
    TU.AverageBounty,
    TU.BadgeCount,
    COALESCE(UC.CommentCount, 0) AS CommentCount,
    COALESCE(UC.UniquePostComments, 0) AS UniquePostComments
FROM 
    TopUsers TU
LEFT JOIN 
    UserComments UC ON TU.UserId = UC.UserId
WHERE 
    TU.ReputationRank <= 10
ORDER BY 
    TU.Reputation DESC;
