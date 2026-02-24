
WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PT.Name AS PostType,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        PH.CreationDate AS LastEditDate
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5)  
    WHERE 
        P.CreationDate >= '2023-01-01'  
),

UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN PV.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN PV.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes PV ON P.Id = PV.PostId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.PostType,
    PD.OwnerDisplayName,
    PD.Score,
    PD.ViewCount,
    PD.AnswerCount,
    PD.CommentCount,
    PD.FavoriteCount,
    PD.LastEditDate,
    US.TotalPosts,
    US.UpVotes,
    US.DownVotes
FROM 
    PostDetails PD
JOIN 
    UserStats US ON PD.OwnerDisplayName = US.DisplayName
ORDER BY 
    PD.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
