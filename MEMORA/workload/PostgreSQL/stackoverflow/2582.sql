
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalViews,
        TotalBounty,
        RANK() OVER (ORDER BY TotalBounty DESC) AS BountyRank,
        DENSE_RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStats
),
ClosedPostReasons AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS TotalClosedPosts
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.UserId
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.Questions,
    TU.Answers,
    TU.TotalViews,
    TU.TotalBounty,
    COALESCE(CPR.TotalClosedPosts, 0) AS TotalClosedPosts,
    CASE 
        WHEN TU.BountyRank = 1 THEN 'Gold' 
        WHEN TU.PostRank = 1 THEN 'Diamond' 
        ELSE 'Regular' 
    END AS UserTier
FROM 
    TopUsers TU
LEFT JOIN 
    ClosedPostReasons CPR ON TU.UserId = CPR.UserId
WHERE 
    TU.TotalPosts > 0
ORDER BY 
    TU.TotalBounty DESC, 
    TU.TotalViews DESC;
