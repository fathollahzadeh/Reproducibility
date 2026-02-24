WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        PH.UserDisplayName AS LastEditor,
        PH.CreationDate AS LastEditDate,
        PH.Comment AS EditComment
    FROM 
        Posts P 
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId 
    WHERE 
        PH.PostHistoryTypeId IN (4, 5) 
)
SELECT 
    US.UserId, 
    US.DisplayName, 
    US.Reputation, 
    US.TotalPosts, 
    US.Questions, 
    US.Answers, 
    US.TotalBadges, 
    PA.PostId, 
    PA.Title, 
    PA.CreationDate, 
    PA.ViewCount, 
    PA.Score, 
    PA.LastEditor, 
    PA.LastEditDate, 
    PA.EditComment 
FROM 
    UserStats US
JOIN 
    PostActivity PA ON PA.PostId = (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = US.UserId ORDER BY P.CreationDate DESC LIMIT 1)
ORDER BY 
    US.Reputation DESC, 
    PA.ViewCount DESC;