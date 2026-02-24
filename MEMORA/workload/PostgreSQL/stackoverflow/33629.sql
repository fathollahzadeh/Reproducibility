
WITH RECURSIVE UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS AuthorName,
        COALESCE(PH.UserDisplayName, 'N/A') AS LastEditedBy,
        PH.CreationDate AS LastEditDate,
        P.ViewCount,
        (SELECT COUNT(C.Id) 
         FROM Comments C 
         WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT STRING_AGG(T.TagName, ', ') 
         FROM Tags T 
         WHERE T.WikiPostId = P.Id) AS TagNames
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.CreationDate = (
            SELECT MAX(CreationDate) 
            FROM PostHistory 
            WHERE PostId = P.Id
        )
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPostAuthors AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        SUM(PD.ViewCount) AS TotalViews,
        SUM(PD.Score) AS TotalScore,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostCount
    FROM 
        Users U
    INNER JOIN 
        PostDetails PD ON U.DisplayName = PD.AuthorName
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    UP.UserId,
    UP.UserRank,
    TAP.DisplayName,
    TAP.TotalViews,
    TAP.TotalScore,
    TAP.PostCount,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.CommentCount,
    PD.TagNames,
    CASE 
        WHEN PD.Score > 10 THEN 'High Score'
        WHEN PD.Score BETWEEN 1 AND 10 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    UserPostCounts UP
JOIN 
    TopPostAuthors TAP ON UP.UserId = TAP.UserId
JOIN 
    PostDetails PD ON TAP.DisplayName = PD.AuthorName
WHERE 
    TAP.TotalViews IS NOT NULL
ORDER BY 
    UP.UserRank, TAP.TotalScore DESC;
