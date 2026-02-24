WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        PostCount
    FROM 
        UserPostCounts
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
PostVoteCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
SELECT 
    U.DisplayName,
    UPC.PostCount,
    PVC.VoteCount
FROM 
    Users U
JOIN 
    TopUsers UPC ON U.Id = UPC.UserId
LEFT JOIN 
    PostVoteCounts PVC ON UPC.UserId = PVC.PostId
ORDER BY 
    UPC.PostCount DESC;