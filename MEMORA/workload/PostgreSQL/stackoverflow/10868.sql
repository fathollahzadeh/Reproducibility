WITH UserPostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        OwnerUserId
),
AvgScore AS (
    SELECT 
        AVG(Score) AS AverageScore
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
),
TopUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        UPC.PostCount
    FROM 
        Users U
    JOIN 
        UserPostCounts UPC ON U.Id = UPC.OwnerUserId
    ORDER BY 
        UPC.PostCount DESC
    LIMIT 10  
)

SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT AverageScore FROM AvgScore) AS AverageQuestionScore,
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount
FROM 
    TopUsers TU;