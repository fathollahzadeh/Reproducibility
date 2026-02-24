
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.PostCount,
        UA.TotalBounties,
        ROW_NUMBER() OVER (ORDER BY UA.PostCount DESC) AS Rank
    FROM 
        UserActivity UA
    WHERE 
        UA.PostCount > 0
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(B.Count, 0) AS TagCount,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Tags B ON P.Tags LIKE '%' || B.TagName || '%'
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, B.Count
)
SELECT 
    TU.DisplayName,
    TU.PostCount,
    TU.TotalBounties,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.TagCount,
    PD.CommentCount,
    RANK() OVER (PARTITION BY TU.UserId ORDER BY PD.Score DESC) AS PostRank
FROM 
    TopUsers TU
JOIN 
    PostDetails PD ON TU.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = PD.PostId LIMIT 1)
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Rank, PD.Score DESC;
