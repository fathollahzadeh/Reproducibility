WITH UserScoreSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(V.BountyAmount) AS TotalBountyAmount,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        RANK() OVER (ORDER BY TotalBountyAmount DESC, TotalPosts DESC) AS UserRank
    FROM 
        UserScoreSummary
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 12, 14)  
),
AggregateComments AS (
    SELECT 
        C.PostId,
        STRING_AGG(C.Text, ' | ') AS AllComments
    FROM 
        Comments C
    GROUP BY 
        C.PostId
)

SELECT 
    U.DisplayName,
    U.TotalBountyAmount,
    U.TotalPosts,
    U.PositivePosts,
    U.AverageScore,
    COALESCE(RPH.Comment, 'No Recent Actions') AS RecentActivity,
    COALESCE(AC.AllComments, 'No Comments') AS PostComments
FROM 
    UserScoreSummary U
LEFT JOIN 
    TopUsers T ON U.UserId = T.UserId
LEFT JOIN 
    RecentPostHistory RPH ON U.UserId = RPH.UserId AND RPH.rn = 1
LEFT JOIN 
    AggregateComments AC ON RPH.PostId = AC.PostId
WHERE 
    U.TotalPosts > 5 AND 
    U.AverageScore <= 0 AND 
    U.UserId IN (SELECT UserId FROM Badges WHERE Class = 1)  
ORDER BY 
    U.TotalBountyAmount DESC, 
    U.TotalPosts DESC;