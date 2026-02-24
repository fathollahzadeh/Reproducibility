WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS Wikis,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),

PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN PHT.Name = 'Edit Body' THEN 1 END) AS EditBodyCount,
        COUNT(CASE WHEN PHT.Name = 'Edit Title' THEN 1 END) AS EditTitleCount,
        STRING_AGG(DISTINCT CAST(PHT.Name AS VARCHAR), ', ') AS ChangeTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),

UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT C.Id) AS CommentCount, 
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostLinks
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        PostLinks PL ON U.Id = PL.PostId
    GROUP BY 
        U.Id
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.Wikis,
    U.TotalScore,
    PHD.LastEditDate,
    PHD.EditBodyCount,
    PHD.EditTitleCount,
    PHD.ChangeTypes,
    UE.CommentCount,
    UE.TotalBounties,
    UE.RelatedPostLinks,
    CASE 
        WHEN U.TotalPosts > 100 THEN 'Active User'
        WHEN UE.CommentCount > 50 THEN 'Engaged User'
        ELSE 'Newbie'
    END AS UserCategory
FROM 
    UserPostStats U
LEFT JOIN 
    PostHistoryDetails PHD ON U.UserId = PHD.PostId
LEFT JOIN 
    UserEngagement UE ON U.UserId = UE.UserId
WHERE 
    U.TotalScore > 0 OR UE.CommentCount > 0
ORDER BY 
    U.TotalScore DESC,
    UE.CommentCount DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY;